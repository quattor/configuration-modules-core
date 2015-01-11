# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::Service::Chkconfig;

use 5.10.1;
use strict;
use warnings;

use parent qw(NCM::Component::Systemd::Service::Unit);

use NCM::Component::Systemd::Service::Unit qw(:targets);
use NCM::Component::Systemd::Systemctl qw(systemctl_show);
use Readonly;

Readonly my $CHKCONFIG => "/sbin/chkconfig";

Readonly::Array my @DEFAULT_RUNLEVEL2TARGET => (
    $TARGET_POWEROFF, # 0
    $TARGET_RESCUE, # 1
    $TARGET_MULTIUSER, $TARGET_MULTIUSER, $TARGET_MULTIUSER, # 234
    $TARGET_GRAPHICAL, # 5
    $TARGET_REBOOT, # 6
    ); 

# Local cache of the mapping between runlevels and targets  
my @runlevel2target;

=pod

=head1 NAME

NCM::Component::Systemd::Service::Chkconfig is a class handling services 
that can be controlled via (older) C<ncm-chkconfig>.

=head2 Public methods

=over

=item new

Returns a new object, accepts the following options

=over

=item services

A hash reference with service as key and a hash reference with properties 
(according to the C<ncm-chkconfig> schema) as value.

This is typical the return value of 
     $config->getElement("/software/components/chkconfig")->getTree

=item log

A logger instance (compatible with C<CAF::Object>).

=back

=cut

sub _initialize
{
    my $self = shift;

    my $initec = $self->SUPER::_initialize(@_);

    if ($initec) {
        $self->generate_runlevel2target();
    };

    return $initec;
}

=pod

=back

=head2 Private methods

=over

=item generate_runlevel2target

Create, set and return the C<runlevel2target> map 
(will reset existing one, return is merely for testing).

=cut

sub generate_runlevel2target
{
    my $self = shift;

    # convenience lookup hash
    my %targets = map { $_ => 1 } @DEFAULT_RUNLEVEL2TARGET;

    # reset
    @runlevel2target = ();

    foreach my $lvl (0..6) {
        my $target = $DEFAULT_RUNLEVEL2TARGET[$lvl];
        my $id = systemctl_show($self, "runlevel$lvl.target")->{Id};

        # Is it a target?
        if ($id && $id =~ m/^(.*)\.target$/) {
            if (! exists($targets{$1})) {
                $self->verbose("Target $1 for level $lvl none of default targets");
            } elsif (! ($target eq $1)) {
                $self->verbose("Target $1 for level $lvl different from default $target");
            } else {
                $self->verbose("Target $1 for level $lvl found.");
            }
            $target = $1;
        } else {
            $id = "<undef>" if (!defined($id)); # handle unitialized value warning
            $self->warn("Unable to identify target for runlevel$lvl.target (Id $id).",
                        " Using default target $target for level $lvl.");
        }
        push(@runlevel2target, $target);
    }
    
    return \@runlevel2target;   
}

=pod

=back

=cut 

1;
