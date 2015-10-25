# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::postgresql;

use strict;
use warnings;

use parent qw(NCM::Component);

use NCM::Component::Postgresql::Service qw($POSTGRESQL);

use LC::Exception;
our $EC = LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Element;

use POSIX qw(strftime);

use File::Copy;
use File::Path;
use File::Compare;

# for units etc
use MIME::Base64;
use Digest::MD5 qw(md5_hex);

use Readonly;

Readonly my $SYSCONFIG_TT => 'sysconfig';

# relative to self->prefix
Readonly my $CONFIG_REL => '/config';

# relative filename in PGDATA
# legacy full text config relative to sefl->prefix
Readonly::Hash my %MAIN_CONFIG => {
    NAME => 'main',
    TT => 'main_config',
    CONFIG => $CONFIG_REL.'/main',
    CONFIG_EL => $CONFIG_REL.'/main',
    FILENAME => 'postgresql.conf',
    TEXT => 'postgresql_conf',
};
Readonly::Hash my %HBA_CONFIG => {
    NAME => 'hba',
    TT => 'hba_config',
    CONFIG => $CONFIG_REL.'/hba',
    CONFIG_EL => $CONFIG_REL, # TT file expects this
    FILENAME => 'pg_hba.conf',
    TEXT => 'pg_hba',
};

Readonly my $DEFAULT_PORT => 5432;
Readonly my $DEFAULT_BASEDIR => "/var/lib/pgsql";

# v is some sort of context / content / key=value of each file
# p is a per file detail (e.g. format)
my (%v, %p);

# only ncm-dcache code
#   slurp
#   case_insensitive (slurp -> capit)
#   EQUAL_SPACE
#   ALL_POOL

=pod

=head1 DESCRIPTION

The component to configure postgresql databases

=head1 public methods

=over

=item create_postgresql_config

Create main or hba config via textrender. Returns undef on failure, changed state otherwise.
The C<data> hash is either C<%MAIN_CONFIG> or C<%HBA_CONFIG>.

=cut

sub create_postgresql_config
{
    my ($self, $config, $iam, %data);

    my $fh;
    my $filename = "$iam->{pg}->{data}/$data{FILENAME}";
    # default empty string, so can be used as boolean
    my $text = $self->fetch($config, $data{TEXT});

    # new style precedes
    if ($config->elementExists($self->prefix().$data{CONFIG})) {
        $self->verbose("rendering $data{NAME} configuration data");
        my $trd = EDG::WP4::CCM::TextRender->new(
            $data{TT},
            $config->getElement($self->prefix().$data{CONFIG_EL}),
            relpath => 'postgresql',
            log => $self,
            );

        $fh = $trd->filewriter($filename, log => $self);
        if(! defined($fh)) {
            $self->error("Failed to render $data{NAME} postgresql config: $trd->{fail}");
            return;
        }
    } elsif ($text) {
        $self->verbose("legacy full text $data{NAME} configuration data");
        $fh = CAF::FileWriter->new(filename, log => $self);
        print $fh $text;
    } else {
        $self->error("config path $base for $data{NAME} config not found.");
        return;
    };

    return $fh->close() ? 1 : 0;
}

=item fetch

Get C<$path> from C<$config>, if it does not exists, return C<$default>.
If C<$default> is not defined, use empty string as default.

If C<$path> is a relative path, it is assumed relative from C<$self->prefix>.

=cut

# TODO: move to NCM::Component? (with a better name)

sub fetch
{
    my ($self, $config, $path, $default) = @_;

    $default = '' if (! defined($default));

    $path = $self->prefix."/$path" if ($path !~ m/^\//);

    my $value;
    if ($config->elementExists($path)) {
        $value = $config->getValue($path);
    } else {
        $value = $default;
    }

    return $value;
}

=item version

Return arrayref with [major, minor, remainder] version information (from postmaster --version)

Return undef in case of problem.

=cut

sub version
{
    my ($self, $pg_engine) = @_;

    my $proc = CAF::Process->new(
        ["$pg_engine/postmaster", "--version"],
        log => $self,
        );
    my $output = $proc->output();

    # e.g. 'postgres (PostgreSQL) 9.2.1'
    if ($output && $output =~ m/\s(\d+)\.(\d+).(\d+)\s*$/) {
        return [$1, $2, $3];
    } else {
        $self->warn("Failed to parse output from $proc: $output");
        return;
    }
}

=item initdb

Initialise the database. End result is a stopped initialised database.

Returns undef on failure.

=cut

sub initdb
{

    my ($self, $iam) = @_;

    $self->info("Initdb, stopping $iam->{service}.");
    $iam->{service}->status_stop();

    # if /usr/pgsql/bin/postgresql-setup, exists, use it with initdb arg
    # else, if >= 8.2, try service postgresql initdb
    # else, just start

    my $setup = "$iam->{pg}->{engine}/postgresql$iam->{pg}->{exesuffix}-setup";
    my $is_recent_enough = (($iam->{version}->[0] > 8) ||
                            (($iam->{version}->[0] == 8 ) && $iam->{version}->[1] >= 2));
    $self->verbose("initdb with setup $setup and is_recent_enough $is_recent_enough");
    if ($self->_file_exists($setup)) {
        $self->verbose("initdb with setup $setup");
        my $proc = CAF::Process->new([$setup, 'initdb'], log => $self);
        my $output = $proc->output();

        if ($?) {
            $self->error("Failed to initialise the database with setup $setup.");
            return;
        }
    } elsif ($is_recent_enough) {
        $self->verbose("initdb without setup $setup, but with initdb service action");
        return if (! $iam->{service}->initdb());
    } else {
        $self->verbose("initdb with old version. Just going to start and hope all will be ok.");
        return if (! $iam->{service}->forcerestart_service());
    }

    # initdb ends with stopped service (configuration still needs to happen)
    return if(! $iam->{service}->status_stop());

    return SUCCESS;
}


=item prepare_service

Perform installation sanity check, and generates the
pgsql sysconfig entry.

Returns undef on failure, the changed state of the pgsql
sysconfig file otherwise

=cut

# for units, you need a new unit with content like
# ncm-systemd can do this for you (set replace = true)
# .include /lib/systemd/system/postgresql.service
# [Service]
# Environment=PGPORT=5433

# TODO: how do we check this, esp PGDATA and PGPORT

sub prepare_service
{
    my ($self, $iam) = @_;

    my ($svc_def_fn, $svc_fn) = $service->installation_files($iam->{defaultservice});

    if (! -e $svc_def_fn) {
        $self->error("Default service file $svc_def_fn for service $default not found.",
                     " Check your postgres installation.");
        return;
    }

    if (! -e $svc_fn) {
        $self->error("Service file $svc_fn for service $name not found.",
                    " Should be configured through one of the service components.");
        return;
    }

    # this is not a file controllable with ncm-sysconfig, it's in a subdir
    # the directory seems present even on linux_systemd (altough unused)
    my $sysconfig_data;
    foreach my $var (qw(dir log port)) {
        $sysconfig_data->{"pg$var"} = $iam->{pg}->{$var};
    }

    my $sysconfig_fn = "/etc/sysconfig/pgsql/$name";
    my $trd = EDG::WP4::CCM::TextRender->new(
        $SYSCONFIG_TT,
        $sysconfig_data,
        relpath => 'postgresql',
        log => $self,
        );
    my $fh = $trd->filewriter(
        $sysconfig_fn,
        log => $self,
        );
    if($fh) {
        my $changed = $fh->close() ? 1 : 0; # force to 0/1
        return $changed;
    } else {
        $self->error("Failed to render postgresql sysconfig $sysconfig_fn: $trd->{fail}");
        return;
    }
}

=item whomai

Return a hashref with configuration related data to indentify
the service to use

=over

=item service

Service instance to use

=item version

Return value from C<version> method

=item pg

A hashref with postgresql basic configuration data,
required to start the database.

=over

=item dir

The database base directory

=item data

The database 'data' subdirectory

=item port

The database port

=item log

The database startup log

=item engine

Location of service binaries

=back

=item suffix

Version related suffix (or empty string if none is required).
E.g. '-9.2', part of e.g. default servicename, pg_engine, ...

=item exesuffix

Version related suffix for certain executables, like '92' in
'postgresql92-setup'.

=item defaultname

The default service name

=item servicename

The actual servicename

=item service

The C<NCM::Component::Postgresql::Service> instance

=back

Return hashref or undef on failure. No errors are logged

=cut

sub whoami
{
    my ($self, $config) = @_;

    my $iam = {};

    my $pg_engine = $self->fetch($config, "pg_engine", "/usr/bin/");
    $self->verbose("iam pg_engine $iam->{pg_engine}");

    $iam->{version} = $self->version($pg_engine);
    return if (! $iam->{version});

    $self->verbose("iam version ", join(' . ', @{$iam->{version}}), '.');

    my $pg_dir = $self->fetch($config, "pg_dir", $DEFAULT_BASEDIR);
    $iam->{pg} = {
        data => "$pg_dir/data",
        dir => $pg_dir,
        engine => $pg_engine,
        log => "$pg_dir/pgstartup.log",
        port => $self->fetch($config, "pg_port", $DEFAULT_PORT),
    };

    $self->verbose("iam pg dir $iam->{pg}->{dir} port $iam->{pg}->{port}",
                   " data $iam->{pg}->{data} log $iam->{pg}->{log}");

    my $pg_version = $self->fetch($config, "pg_version", "");
    my $pg_version_suf = $pg_version ? "-$pg_version" : "";
    $iam->{suffix} = $pg_version_suf;
    $self->verbose("iam suffix $iam->{suffix}");

    my $exesuffix_def = $pg_version;
    $exesuffix_def =~ s/\.//g;
    $iam->{exesuffix} = $self->fetch($config, "bin_version", $exesuffix_def);
    $self->verbose("iam exesuffix $iam->{exesuffix}");

    my $iam->{defaultname} = "$POSTGRESQL$iam->{suffix}";
    my $iam->{servicename} = $self->fetch($config, "pg_script_name", $iam->{defaultname});

    my $service = NCM::Component::Postgresql::Service->new(
        name => $iam->{servicename},
        log => $self,
        );

    if ($service) {
        $self->verbose("iam service instance created for name $iam->{servicename}");
        $iam->{service} = $service;
    } else {
        $self->warn("Failed to create service instance with name $iam->{servicename}");
        return;
    }

    $self->verbose("iam service $iam->{service}");

    return $iam;
}

=item sanity_check

Run some additional sanity checks, return undef on failure.

=cut

sub sanity_check
{
    my ($self, $iam) = @_;

    # some very nasty conditions once encountered
    $self->debug(1, "Starting some additional checks.");
    if ($self->_directory_exists($iam->{pg}->{data}) && (! $self->_file_exists("$iam->{pg}->{data}/PG_VERSION"))) {
        # ok, postgres will never like this
        # can't believe it will be running, but just to be certain
        $iam->{service}->status_stop();

        # non-destructive mode: make a backup
        my $moved_suffix = "-moved-for-postgres-by-ncm-" . $self->name() . "." . strftime('%Y%m%d-%H%M%S', localtime());
        my $bck_data = "$iam->{pg}->{data}$moved_suffix";
        if (move($iam->{pg}->{data}, $bck_data)) {
            $self->warn("Moved $iam->{pg}->{data} to $bck_data.");
        } else {
            # it will never work, but next time make sure all goes well
            $self->error("Can't move $iam->{pg}->{data} to $bck_data. Please clean up.");
            return;
        }
    }

    return SUCCESS;
}

=item start_postgres

Try to start postgres service, the cautious way.

Return undef on failure, SUCCESS otherwise.

=cut

sub start_postgres
{

    my ($self, $iam, $sysconfig_changed) = @_;

    # it's possible that PG_VERSION file doesn't yet exist (or even basedir PGDATA).
    # we assume this is only due to pre-init postgres
    if(! $self->_file_exists("$iam->{pg}->{data}/PG_VERSION")) {
        return if(! $self->initdb($iam));
        if(! $self->_file_exists("$iam->{pg}->{data}/PG_VERSION")) {
            $self->error("Succesful initdb but PG_VERSION still missing.");
            return;
        }
    }

    # only now we can generate the config files
    # PGDATA has to exist
    my $main_changed = $self->create_postgresql_config($config, $iam, %MAIN_CONFIG);
    return if (! defined($main_changed));

    my $hba_changed = $self->create_postgresql_config($config, $iam, %HBA_CONFIG);
    return if (! defined($hba_changed));

    if ($hba_changed) {
        $self->info("hba config changed, reloading");
        return if (! $iam->{service}->status_reload());
    } elsif ($main_changed || $sysconfig_changed) {
        # most main params don't require a restart, but a few do.
        $self->info("main config or sysconfig changed, restarting");
        return if (! $iam->{service}->status_restart());
    } else {
        $self->verbose("Nothing changed, nothing to do");
    }

    # start if not yet running
    return if (! $iam->{service}->status_start());

    return SUCCESS;
}



sub Configure {
    my ($self, $config) = @_;

    my $iam = $self->whoami($config);
    if (! $iam) {
        $self->error('Failed to determine setup details. (See errors/warnings above).');
        return 1;
    };

    my $sysconfig_changed = $self->prepare_service($iam, $default_service);
    return 1 if (! defined($sysconfig_changed));

    # now that prepare_service ran, we can start checking the service

    # get current state
    $self->verbose("Checking current status. Will be the same status after the component finishes.");
    my $current_status = $iam->{service}->status();
    $self->verbose("Current status: $current_status.");

    # this might remove PGDATA
    $return 1 if (! defined($self->sanity_check));

    # try to (re)start postgres in state that is configured as intended
    return 1 if(! defined($self->start_postgres($iam, $sysconfig_changed)));

    # so now we have a running postgres
    # make some more database configurations
    return 1 if (! defined($self->pg_alter($config, $iam)));

    # set postgres status to what it was
    $self->verbose("Setting status to what it was before the component ran: $current_status.");
    if ($current_status) {
        $iam->{service}->status_start();
    } else {
        $iam->{service}->status_stop();
    }

    return 1;
}


sub pg_alter
{
    my ($self, $config, $iam) = @_;

    return SUCCESS;
}

======================HERE

    # we're going to use this file to check if one should run the "ALTER ROLE" commands.
    # if not, i think running pg_alter unnecessary might cause transfer errors.
    # to protect the passwds, the file will contain md5 hashes of the psql commands
    $name = "pg_alter";
    $p{$name}{mode} = "MD5_HASH";
    $p{$name}{filename} = "$pg_dir/data/pg_alter.ncm-".$self->name();
    $p{$name}{write_empty} = 0;


        } elsif ($mode =~ m/MD5_HASH/) {
            # what could possibly go wrong here?
            my $md5=md5_hex($v{$name}{$k});
            print FILE "$k=$md5\n";

  # ## Generated by ncm-postgresql
  # ## DO NOT EDIT
  # gold=48401f21bddd6bce6ae6d00f0112be91
  # vsc_accountpage_admin=3377bfb671f512a7e461c675fef0bd5f


##########################################################################
    sub pg_alter {
##########################################################################
        my $func = "pg_alter";
        $self->debug(1, "$func: function called with arg: @_");

        my $new_base = shift;
        my $name="pg_alter";

        my $exitcode=1;
        # configure users/roles: list them with psql -t -c "SELECT rolname FROM pg_roles;"
        # a user is a role with the LOGIN attribute set
        my @all_roles=();
        open(TEMP,"$su -l postgres -c \"psql -t -c \\\"SELECT rolname FROM pg_roles;\\\"\" |")||$self->error("$func: SELECT rolname FROM pg_roles failed: $!");
        while(<TEMP>) {
            chomp;
            s/ //g;
            push(@all_roles,$_);
        }
        close TEMP;
        my ($exi,$real_exec);
        my ($role,$rol,$r,$rol_opt);
        if ($config->elementExists("$new_base/roles")) {
            my $roles = $config->getElement("$new_base/roles");
            while ($roles->hasNextElement() ) {
                $role = $roles->getNextElement();
                $rol = $role->getName();
                # check if role exists, if not create it
                $exi=0;
                foreach $r (@all_roles) {
                    if ($r eq $rol) { $exi=1;}
                }
                if (! $exi) {
                    $self->verbose("$func: Role $rol does not exist. Creating...");
                    $real_exec="$su -l postgres -c \"psql -c \\\"CREATE ROLE \\\\\\\"$rol\\\\\\\"\\\"\"";
                    $self->error("$func: Executing $real_exec failed") if (sys2($real_exec));
                }
                # set defined attributes to role
                $rol_opt = $role->getValue();
                $v{$name}{$rol}=$rol_opt;
            }
        }

        dump_it($name,"WRITE");
        if ($p{$name}{changed}) {
            # apparently something has changed.
            $self->verbose("$func: Something changed to the roles attributes.");
            foreach $rol (keys %{$v{$name}}) {
                $self->verbose("$func: Role $rol: setting attributes...");
                # run without logger!!
                $real_exec="$su -l postgres -c \"psql -c \\\"ALTER ROLE \\\\\\\"$rol\\\\\\\" ".$v{$name}{$rol}.";\\\"\"";
                # Passwds could be shown with this: $self->info("$real_exec");
                if (sys2($real_exec,"false","nothing")) {
                    $self->error("$func: Executing ALTER ROLE $rol failed (attributes not shown for passwd reasons)");
                    $exitcode=0;
                }
            }
        }

        my ($database,$datab,$datab_user,$datab_el,$datab_elem,$datab_file,$datab_sql_user,$datab_lang,$datab_lang_file);
        if ($config->elementExists("$new_base/databases")) {
            my $databases = $config->getElement("$new_base/databases");
            while ($databases->hasNextElement() ) {
                $database = $databases->getNextElement();
                $datab = $database->getName();
                $datab_el = $config->getElement("$new_base/databases/".$datab);
                $datab_file = "";
                $datab_lang = "";
                $datab_lang_file = "";
                $datab_sql_user= "REALLY_NOBODY";
                while ($datab_el->hasNextElement() ) {
                    $datab_elem = $datab_el->getNextElement();
                    $datab_user = $datab_elem->getValue() if ($datab_elem->getName() eq "user");
                    $datab_sql_user = $datab_elem->getValue() if ($datab_elem->getName() eq "sql_user");
                    $datab_file = $datab_elem->getValue() if ($datab_elem->getName() eq "installfile");
                    $datab_lang = $datab_elem->getValue() if ($datab_elem->getName() eq "lang");
                    $datab_lang_file = $datab_elem->getValue() if ($datab_elem->getName() eq "langfile");
                }
                $datab_sql_user = $datab_user if ($datab_sql_user eq "REALLY_NOBODY");
                $exitcode = create_pgdb($datab,$datab_user,$datab_file,$datab_lang,$datab_lang_file,$datab_sql_user);
            }
        }
        return $exitcode;
    }

##########################################################################
    sub create_pgdb {
##########################################################################
        my $func = "create_pgdb";
        $self->debug(1, "$func: function called with arg: @_");

        my $datab = shift;
        my $datab_user = shift;
        my $datab_file = shift;
        my $datab_lang = shift;
        my $datab_lang_file = shift;
        my $datab_run_sql_user = shift ||$datab_user;
        my $exitcode = 1;

        my $su;
        # taken from the init.d/postgresql script: For SELinux we need to use 'runuser' not 'su'
        if (-x "/sbin/runuser") {
            $su="runuser";
        } else {
            $su="su";
        }

        # configure databases: list all databases with psql -t -c "SELECT datname FROM pg_database;"
        my @all_databases=();
        open(TEMP,"$su -l postgres -c \"psql -t -c \\\"SELECT datname FROM pg_database;\\\"\" |")||$self->error("$func: SELECT datname FROM pg_database failed: $!");
        while(<TEMP>) {
            chomp;
            s/ //g;
            push(@all_databases,$_);
        }
        close TEMP;

        # check if database exists, if not create it
        my $exi=0;
        foreach my $d (@all_databases) {
            $exi=1 if ($d eq $datab);
        }
        if (! $exi) {
            $self->verbose("$func: Database $datab does not exist. Creating...");
            my $real_exec="$su -l postgres -c \"psql -c \\\"CREATE DATABASE \\\\\\\"$datab\\\\\\\" OWNER \\\\\\\"$datab_user\\\\\\\";\\\"\"";
            my ($exitcode,$output) = sys2($real_exec,"false","true");
            if (! $exitcode) {
                if (($datab_file ne "") && (-e $datab_file)) {
                    $self->verbose("$func: Creating $datab: initialising with $datab_file.");
                    $real_exec="$su -l postgres -c \"psql -U $datab_run_sql_user $datab -f $datab_file;\"";
                    ($exitcode,$output) = sys2($real_exec,"false","true");
                    if ($exitcode) {
                        $self->error("$func: Executing $real_exec failed:\n$output");
                        $exitcode=0;
                    }
                }
                # check for db lang
                if ($datab_lang ne "") {
                    $self->verbose("$func: Creating $datab: setting lang $datab_lang.");
                    $real_exec="$su -l postgres -c \"createlang $datab_lang $datab;\"";
                    ($exitcode,$output) = sys2($real_exec,"false","true");
                    if ($exitcode) {
                        $self->error("$func: Executing $real_exec failed:\n$output");
                        $exitcode=0;
                    } else {
                        # db lang init file
                        if (($datab_lang_file ne "") && (-e $datab_lang_file)) {
                            $self->verbose("$func: Creating $datab: initialising lang $datab_lang with $datab_lang_file.");
                            $real_exec="$su -l postgres -c \"psql -U $datab_run_sql_user $datab -f $datab_file;\"";
                            ($exitcode,$output) = sys2($real_exec,"false","true");
                            if ($exitcode) {
                                $self->error("$func: Executing $real_exec failed:\n$output");
                                $exitcode=0;
                            }
                        }
                    }
                }
            } else {
                $self->error("$func: Executing $real_exec failed with:\n$output");
            }
        }
        return $exitcode;
    }


=pod

=back

=head2 Private methods

=over

=item _file_exists

Test if file exists

=cut

# TODO: move to CAF
sub _file_exists
{
    my ($self, $filename) = @_;
    return (-l $filename || -f $filename);
}

=item _directory_exists

Test if directory exists

=cut

# TODO: move to CAF
sub _directory_exists
{
    my ($self, $directory) = @_;
    return -d $directory;
}


=pod

=back

=cut

1;
