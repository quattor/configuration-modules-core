# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::UnitFile;

use 5.10.1;
use strict;
use warnings;

use parent qw(CAF::Object Exporter);

use File::Path qw(rmtree);
use File::Copy qw(move);

use Scalar::Util qw(blessed);

use LC::Exception qw (SUCCESS);
use Readonly;
use LC::Check;

use EDG::WP4::CCM::TextRender 17.2.1;
use NCM::Component::Systemd::Systemctl qw(systemctl_daemon_reload);

Readonly my $UNITFILE_DIRECTORY => '/etc/systemd/system';
Readonly my $NOREPLACE_FILENAME => 'quattor.conf';

Readonly my $UNITFILE_TT => 'unitfile';

Readonly::Hash our %CUSTOM_ATTRIBUTES => {
    CPUAffinity => '_hwloc_calc_cpuaffinity',
};

Readonly::Array my @HWLOC_CALC_CPUS => qw(hwloc-calc --physical-output --intersect PU);

Readonly::Hash my %CLEANUP_DISPATCH => {
    move => \&move,
    rmtree => \&rmtree,
    unlink => sub { return unlink(shift); },
};

=pod

=head1 NAME

NCM::Component::Systemd::UnitFile handles the configuration of C<ncm-systemd> unitfiles.

=head2 Public methods

=over

=item new

Returns a new object, accepts the following mandatory arguments

=over

=item unit

The unit (full C<name.type>).

=item config

A C<EDG::WP4::CCM::CacheManager::Element> instance with the unitfile configuration.

(An element instance is required becasue the rendering of
the configuration is pan-basetype sensistive).

=back

and options

=over

=item replace

A boolean to replace the configuration. (Default/undef is false).

For a non-replaced configuration, a directory
C<</etc/systemd/system/<unit>.d>> is created
and the unitfile is C<</etc/systemd/system/<unit>.d/quattor.conf>>.
Systemd will pickup settings from this C<quattor.conf> and other C<.conf> files
in this directory,
and also any configuration for the unit in the default systemd paths (e.g. typical
unit part of the software package located in
C<</lib/systemd/system/<unit>>>).

A replaced configuration overrides all existing system unitfiles
for the unit (and has to define all attributes). It has filename
C<</etc/systemd/system/<unit>>>.

=item backup

Backup files and/or directories.

=item custom

A hashref with custom configuration data. See C<custom> method.

=item log

A logger instance (compatible with C<CAF::Object>).

=back

=cut

sub _initialize
{
    my ($self, $unit, $el, %opts) = @_;

    $self->{unit} = $unit;
    $self->{config} = $el;

    $self->{replace} = $opts{replace} ? 1 : 0; # replace 0 / 1
    $self->{backup} = $opts{backup} if $opts{backup};

    $self->{custom} = $opts{custom} if $opts{custom};
    $self->{log} = $opts{log} if $opts{log};

    return SUCCESS;
}

=item custom

The C<custom> method prepares configuration data that is cannot be
found in the profile.

Report hashref with custom data on success, undef otherwise.

Following custom attributes are supported:

=over

=item CPUAffinity

Obtain the C<systemd.exec> C<CPUAffinity> list determined via C<hwloc(7)> locations.

Allows to e.g. cpubind on numanodes using the C<node:X> location

Forces an empty list to reset any possible previously defined affinity.

=back

=cut

sub custom
{
    my ($self) = @_;

    my $res = {};

    foreach my $attr (keys %{$self->{custom}}) {
        my $method = $CUSTOM_ATTRIBUTES{$attr};
        if ($method) {
            # the existence is unittested
            if($self->can($method)) {
                my $value = $self->$method($self->{custom}->{$attr});
                if (defined($value)) {
                    $res->{$attr} = $value;
                } else {
                    $self->error("Method $method for custom attribute $attr failed.");
                    return;
                }
            } else {
                $self->error("Unsupported method $method for custom attribute $attr.");
                return;
            }
        } else {
            $self->error("Unsupported custom attribute $attr.");
            return;
        }
    }

    return $res;
}

=item write

Create the unitfile. Returns undef in case of problem,
a boolean indication if something changed otherwise.

(This method will take all required actions to use the values, like
reloading the systemd daemon.
It will not however change the state of the unit,
e.g. by restarting it.)

=cut

sub write
{
    my ($self) = @_;

    if (!(blessed($self->{config}) &&
           $self->{config}->isa("EDG::WP4::CCM::CacheManager::Element"))) {
        $self->error("config has to be an Element instance");
        return;
    }

    # custom values
    my $custom = $self->custom();
    return if (! defined($custom));

    # prepare/cleanup destination and return filename
    my $filename = $self->_prepare_path($UNITFILE_DIRECTORY);
    return if(! defined($filename));

    # render
    my $trd = EDG::WP4::CCM::TextRender->new(
        $UNITFILE_TT,
        $self->{config},
        relpath => 'systemd',
        log => $self,
        ttoptions => _make_variables_custom($custom),
        );

    # write
    my $fh = $trd->filewriter(
        $filename,
        backup => $self->{backup},
        mode => 0664,
        log => $self,
        );

    if(! defined($fh)) {
        $self->error("Rendering unitfile for unit $self->{unit}",
                     " (filename $filename) failed: $trd->{fail}.");
        return;
    }

    my $changed = $fh->close() ? 1 : 0; # force to 1 or 0

    # if changed, reload daemon
    if($changed) {
        # can't do much with return value?
        systemctl_daemon_reload($self);
    }

    return $changed;
}

=pod

=back

=head2 Private methods

=over

=item _prepare_path

Create and return the filename to use,
and prepare the directory structure if needed.

C<basedir> is the base directory to use, e.g. C<$UNITFILE_DIRECTORY>.

=cut

sub _prepare_path
{
    my ($self, $basedir) = @_;

    my $filename;

    my $unitfile = "$basedir/$self->{unit}";
    my $unitdir = "${unitfile}.d";

    if ($self->{replace}) {
        # unitdir can't exist
        return if (! $self->_cleanup($unitdir));

        $filename = $unitfile;
    } else {
        # unitfile can't exist
        return if (! $self->_cleanup($unitfile));

        $filename = "$unitdir/$NOREPLACE_FILENAME";
        if (! ($self->_directory_exists($unitdir) || $self->_make_directory($unitdir))) {
            $self->error("Failed to create unitdir $unitdir: $!");
            return;
        }
    };

    return $filename;
}

=item _hwloc_calc_cpuaffinity

Run C<_hwloc_calc_cpus>, and returns in C<CPUAffinity> format with a reset

=cut

sub _hwloc_calc_cpuaffinity
{
    my ($self, $locations) = @_;

    my $cpus = $self->_hwloc_calc_cpus($locations);
    return if(! defined($cpus));

    # first empty list, to reset all previous defined CPUaffinity settings
    return [[], $cpus];
}


=item _hwloc_calc_cpus

Run the C<hwloc-calc --physical --intersect PU> command for C<locations>.

Returns arrayref with CPU indices on success, undef otherwise.

=cut

sub _hwloc_calc_cpus
{
    my ($self, $locations) = @_;

    # pass a copy of the Readonly array, so we can extend it
    my $proc = CAF::Process->new([@HWLOC_CALC_CPUS], log => $self);
    $proc->pushargs(@$locations);

    my @indices;
    my @unexpected;
    my $output = $proc->output();
    foreach my $line (split("\n", $output)) {
        if($line =~ m/^\d+(,\d+)*$/) {
            @indices = split(/,/, $line);
        } else {
            push(@unexpected, $line) if $line;
        }
    }

    if(@unexpected) {
        $self->warn("Unexpected output from $proc: ", join("\n", @unexpected));
    }

    if (@indices) {
        return \@indices;
    } else {
        $self->error("No indices from from $proc: $output");
        return;
    }
}


=item _make_variables_custom

A function that return the custom variables hashref to pass as ttoptions.
(This is a function, not a method).

=cut

sub _make_variables_custom {
    my $customs = shift;
    my $ttoptions;
    $ttoptions->{VARIABLES}->{SYSTEMD}->{CUSTOM} = $customs;
    return $ttoptions;
}

# TODO: Move to CAF::AllTheMissingBitsThatLCProvides

# make directory, mkdir -p style, wrapper around LC::Check::directory
sub _make_directory
{
    my ($self, $directory) = @_;
    return LC::Check::directory($directory, noaction => $CAF::Object::NoAction);
}

# -d, wrapped in method for unittesting
# -d follows symlink, a broken symlink either exists with -l or not
# and can be cleaned up with rmtree
sub _directory_exists
{
    my ($self, $directory) = @_;
    return (! -l $directory) && -d $directory;
}

# -f, wrapped in method for unittesting
sub _file_exists
{
    my ($self, $filename) = @_;
    return (-f $filename || -l $filename);
}

# exists, -e || -l, wrapped in method for unittesting
# LC::Check::_unlink uses lstat and -e _ (is that a single FS query?)
sub _exists
{
    my ($self, $path) = @_;
    return -e $path || -l $path;
}

# _cleanup, remove with backup support
# works like LC::Check::_unlink, but has directory support
# and no error throwing
# returns SUCCESS on success, undef on failure, logs error
# backup is backup from LC::Check::_unlink (and thus also CAF::File*)
# if backup is undefined, use self->{backup}
# pass empty string to disable backup with self->{backup} defined
# does not cleanup the backup of the original file,
# FileWriter via TextRender can do that.
sub _cleanup
{
    my ($self, $dest, $backup) = @_;

    return SUCCESS if (! $self->_exists($dest));

    $backup = $self->{backup} if (! defined($backup));

    # old is the backup location or undef if no backup is defined
    # (empty string as backup is not allowed, but 0 is)
    # 'if ($old)' can safely be used to test if a backup is needed
    my $old;
    $old = $dest.$backup if (defined($backup) and $backup ne '');

    # cleanup previous backup, no backup of previous backup!
    my $method;
    my @args = ($dest);
    if($old) {
        if (! $self->_cleanup($old, '')) {
            $self->error("_cleanup of previous backup $old failed");
            return;
        };

        # simply rename/move dest to backup
        # works for files and directories
        $method = 'move';
        push(@args, $old);
    } else {
        if($self->_directory_exists($dest)) {
            $method = 'rmtree';
        } else {
            $method = 'unlink';
        }
    }

    if($CAF::Object::NoAction) {
        $self->verbose("CAF::Object NoAction set, not going to $method with args ", join(',', @args));
        return SUCCESS;
    } else {
        if($CLEANUP_DISPATCH{$method}->(@args)) {
            $self->verbose("_cleanup $method removed $dest");
            return SUCCESS;
        } else {
            $self->error("_cleanup $method failed to remove $dest: $!");
            return;
        }
    };
}

=pod

=back

=cut

1;
