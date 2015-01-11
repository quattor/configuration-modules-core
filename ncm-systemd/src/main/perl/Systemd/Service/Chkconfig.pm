# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::Service::Chkconfig;

use 5.10.1;
use strict;
use warnings;

use parent qw(NCM::Component::Systemd::Service::Unit);

use NCM::Component::Systemd::Service::Unit qw(:targets $DEFAULT_TARGET $TYPE_SYSV $DEFAULT_STARTSTOP);
use NCM::Component::Systemd::Systemctl qw(systemctl_show);
use Readonly;

Readonly my $CHKCONFIG => "/sbin/chkconfig";

Readonly::Array my @DEFAULT_RUNLEVEL2TARGET => (
    $TARGET_POWEROFF,    # 0
    $TARGET_RESCUE,      # 1
    $TARGET_MULTIUSER, $TARGET_MULTIUSER, $TARGET_MULTIUSER,    # 234
    $TARGET_GRAPHICAL,                                          # 5
    $TARGET_REBOOT,                                             # 6
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

=item current_services

Return hash reference with current configured services 
determined via C<chkconfig --list>.

(No type to specify, C<sysv> type is forced).

=cut

sub current_services
{
    my $self = shift;

    my %current;

    my $data = CAF::Process->new(
        [$CHKCONFIG, '--list'], 
        log => $self,
        )->output();
    my $ec = $?;
    if ($ec) {
        $self->error("Cannot get list of current services from $CHKCONFIG: ec $ec ($data)");
        return;
    }

    foreach my $line (split(/\n/, $data)) {

        # afs       0:off   1:off   2:off   3:off   4:off   5:off   6:off
        # ignore the "xinetd based services"
        if ($line =~ m/^([\w\-]+)\s+((?:[0-6]:(?:on|off)(?:\s+|\s*$)){7})/) {
            my ($servicename, $levels) = ($1, $2);
            my $detail = {name => $servicename, type => $TYPE_SYSV, startstop => $DEFAULT_STARTSTOP};

            if ($levels =~ m/[0-6]:on/) {
                $self->debug(1, "Found on states for service $servicename");
                my $ontargets = $self->convert_runlevels(join('', $levels =~ /([0-6]):on/g));
                $detail->{state}   = "on";
                $detail->{targets} = $ontargets;
            } else {
                $self->debug(1, "No on states found for service $servicename");
                # TODO include the runlevel 0,1 and 6 in the off-conversion?
                # if the state is off, targets don't really matter
                my $offtargets = $self->convert_runlevels(join('', $levels =~ /([2-5]):off/g));
                $detail->{state}   = "off";
                $detail->{targets} = $offtargets;
            }

            $self->verbose("Add chkconfig service $detail->{name}");
            $self->debug(1, "Add chkconfig ", $self->service_text($detail));
            $current{$servicename} = $detail;
        }
    }
    return \%current;
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
    my %targets = map {$_ => 1} @DEFAULT_RUNLEVEL2TARGET;

    # reset
    @runlevel2target = ();

    foreach my $lvl (0 .. 6) {
        my $target = $DEFAULT_RUNLEVEL2TARGET[$lvl];
        my $id = systemctl_show($self, "runlevel$lvl.target")->{Id};

        # Is it a target?
        if ($id && $id =~ m/^(.*)\.target$/) {
            if (!exists($targets{$1})) {
                $self->verbose("Target $1 for level $lvl none of default targets");
            } elsif (!($target eq $1)) {
                $self->verbose("Target $1 for level $lvl different from default $target");
            } else {
                $self->verbose("Target $1 for level $lvl found.");
            }
            $target = $1;
        } else {
            $id = "<undef>" if (!defined($id));    # handle unitialized value warning
            $self->warn("Unable to identify target for runlevel$lvl.target (Id $id).",
                " Using default target $target for level $lvl.");
        }
        push(@runlevel2target, $target);
    }

    return \@runlevel2target;
}

=pod

=item convert_runlevels

Convert the C<ncm-chkconfig> levels to new systemsctl targets

C<legacylevel> is a string with integers e.g. "234".
Retrun a array reference with the targets.

=cut

sub convert_runlevels
{
    my ($self, $legacylevel) = @_;

    if (!@runlevel2target) {
        $self->verbose("Creating runlevel2target cache");
        $self->generate_runlevel2target;
        if (!@runlevel2target) {
            $self->error("Failed to generate runlevel2target cache");
            return;
        }
    }

    # only keep the relevant ones
    my @targets;
    if (defined($legacylevel)) {
        foreach my $lvl (0 .. 6) {
            if ($legacylevel =~ m/$lvl/) {
                my $target = $runlevel2target[$lvl];
                push(@targets, $target) if (!grep {$_ eq $target} @targets);
            }
        }

        # only for non-default/non-valid runlevels?
        if (!scalar @targets) {
            $self->warn(
                "legacylevel set to $legacylevel, but not converted in new targets. Using default $DEFAULT_TARGET."
            );
            push(@targets, $DEFAULT_TARGET);
        }
        $self->verbose("Converted legacylevel '$legacylevel' in " . join(', ', @targets));
    } else {
        $self->verbose("legacylevel undefined, using default $DEFAULT_TARGET");
        push(@targets, $DEFAULT_TARGET);
    }

    return \@targets;
}

=pod

=back

=cut 

1;
