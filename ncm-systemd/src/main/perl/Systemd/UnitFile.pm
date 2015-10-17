# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::UnitFile;

use 5.10.1;
use strict;
use warnings;

use parent qw(CAF::Object Exporter);

use LC::Exception qw (SUCCESS);

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

A C<EDG::WP4::CCM::Element> instance with the unitfile configuration.

(An element instance is required becasue the rendering of
the configuration is pan-basetype sensistive).

=back

and options

=over

=item force

A boolean to force the configuration. (Default/undef is false).

For a non-forced configuration, a directory
C<</etc/systemd/system/<unit>.d>> is created
and the unitfile is C<</etc/systemd/system/<unit>.d/quattor.conf>>.
Systemd will pickup settings from this C<quattor.conf> and other C<.conf> files
in this directory,
and also any configuration for the unit in the default systemd paths (e.g. typical
unit part of the software package located in
C<</lib/systemd/system/<unit>>>).

A forced configuration overrides all existing system unitfiles
for the unit (and has to define all attributes). It has filename
C<</etc/systemd/system/<unit>>>.

=item backup

Backup files and/or directories.

=item log

A logger instance (compatible with C<CAF::Object>).

=back

=cut

sub _initialize
{
    my ($self, $unit, $el, %opts) = @_;

    $self->{unit} = $unit;
    $self->{config} = $el;

    $self->{force} = $opts{force} ? 1 : 0; # force 0 / 1

    $self->{log} = $opts{log} if $opts{log};

    return SUCCESS;
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

    my $changed;

    # check paths
    # if force,
    # rename any existing dir to name.type.d.bak
    # filename is name.type
    # else create dir
    #   move name.type to name.type.bak
    #   fielname is name.type.d/quattor.conf
    # render
    # write
    # if changed, reload something

    return $changed;
}

=pod

=back

=cut

1;
