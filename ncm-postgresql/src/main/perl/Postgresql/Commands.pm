# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Postgresql::Commands;

use strict;
use warnings;

use CAF::Process;
use parent qw(CAF::Object);
use LC::Exception qw (SUCCESS);

use Readonly;

Readonly my $RUNUSER => '/sbin/runuser';
Readonly my $SU => '/bin/su';

Readonly my $POSTGRESQL_USER => 'postgres';
Readonly my $PROCESS_LOG_ENABLED => 'PROCESS_LOG_ENABLED';

# engine is location of binaries
# set su attribute
# set $PROCESS_LOG_ENABLED attribute to true (enable process logging)
sub _initialize
{
    my ($self, $engine, %opts) = @_;

    # taken from the init.d/postgresql script
    # For SELinux we need to use 'runuser' not 'su'
    $self->{su} = $self->_file_exists($RUNUSER) ? $RUNUSER : $SU;

    $self->{engine} = $engine || '/no/engine/defined';

    $self->{$PROCESS_LOG_ENABLED} = 1;

    $self->{log} = $opts{log} if exists($opts{log});

    return SUCCESS;
}

# return $su -l postgres -c '@$args' CAF::Process output.
# return undef on failure
# supported opts: keeps_state
sub run_postgres
{
    my ($self, $args, %opts) = @_;

    my $cmd = [$self->{su}, '-l', $POSTGRESQL_USER, '-c', join(' ', @$args)];

    my $log = $self->{$PROCESS_LOG_ENABLED} ? $self->{log} : undef;
    my $proc = CAF::Process->new($cmd, log => $log, keeps_state => $opts{keeps_state} ? 1 : 0);
    my $output = $proc->output();

    my $method = $? ? "error" : "verbose";
    my $res = $? ? undef : $output;

    $self->$method("Command $proc exitcode $? output $output") if $self->{$PROCESS_LOG_ENABLED};

    return $res;
}

# return $su -l postgres -c 'psql -t -c "arg"' CAF::Process instances
# always -t
# args are space joined and wrapped in single quotes
# a ';' is added, none of @args can contain a ';'
# double quotes in @args are escaped
# opts passed on to run_postgres as is
sub run_psql
{
    my ($self, $args, %opts) = @_;

    my @postgresargs = ("$self->{engine}/psql", "-t", "-c");

    my $sql = join(' ', @$args);
    if ($sql =~ m/;/) {
        my $invalidmsg = "psql args cannot contain a ';'";
        $invalidmsg .= " (sql: $sql)" if $self->{$PROCESS_LOG_ENABLED};
        $self->error($invalidmsg);
        return;
    };

    # escape double quotes
    $sql =~ s/"/\\"/g;

    push(@postgresargs, "\"$sql;\"");

    return $self->run_postgres(\@postgresargs, %opts);
}

# simple select: one column from one table
# return array ref with all values. undef on failure
sub simple_select
{
    my ($self, $column, $table) = @_;

    my $output = $self->run_psql(["SELECT", $column, "FROM", $table], keeps_state => 1);
    return if (! defined($output));

    # right-to-left:
    #   split on newlines
    #   output can have sort of indentation, remove them with map'ped search and replace
    #   as last, remove empty lines with grep
    my @res = grep {$_ =~ m/\S/} map {s/^\s+//; s/\s+$//; $_} split(/\n/, $output);

    $self->verbose("Found ", scalar @res, " $column from $table: ",join(', ', @res))
        if $self->{$PROCESS_LOG_ENABLED};

    return \@res;
}

# return arrayref with existing roles, undef in case of failure
sub get_roles
{
    my ($self) = @_;

    return $self->simple_select('rolname', 'pg_roles');
}

# create role
sub create_role
{
    my ($self, $role) = @_;

    return $self->run_psql(["CREATE", "ROLE", '"'.$role.'"']);
}

# alter role with sql
# command itself is not logged
sub alter_role
{
    my ($self, $role, $sql) = @_;

    # Passwords (plain or encrypted) could be shown without disabling
    my $oldproclog = $self->{$PROCESS_LOG_ENABLED};
    $self->{$PROCESS_LOG_ENABLED} = 0;

    # role in quotes
    my $res = $self->run_psql(['ALTER', 'ROLE', '"'.$role.'"', $sql]);

    # restore old proclog setting
    $self->{$PROCESS_LOG_ENABLED} = $oldproclog;

    if (defined($res)) {
        $self->verbose("Altered role $role.");
        return SUCCESS;
    } else {
        $self->error("Failed to alter role $role.");
        return;
    }
}

# return arrayref with databases
sub get_databases
{
    my ($self) = @_;

    return $self->simple_select('datname', 'pg_database');
}

# create database with owner
sub create_database
{
    my ($self, $database, $owner) = @_;

    return $self->run_psql(["CREATE", "DATABASE", '"'.$database.'"', "OWNER", '"'.$owner.'"']);
}

# createlang for database
sub create_database_lang
{
    my ($self, $database, $lang) = @_;
    return $self->run_postgres(["$self->{engine}/createlang", $database, $lang]);
}

# execute number of commands defined in file filename
sub run_commands_from_file
{
    my ($self, $database, $asuser, $filename) = @_;

    if (! $self->_file_exists($filename)) {
        $self->error("Cannot find filename $filename to run commands from");
        return;
    }

    return $self->run_postgres(["$self->{engine}/psql", '-U', $asuser, '-f', $filename, $database]);
}

# TODO should be moved to CAF
# _file_exists
# Test if file exists

sub _file_exists
{
    my ($self, $filename) = @_;
    return (-l $filename || -f $filename);
}

1;
