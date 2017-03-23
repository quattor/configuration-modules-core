# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::Service::Chkconfig;

use 5.10.1;
use strict;
use warnings;

use parent qw(NCM::Component::Systemd::Service::Unit);

use EDG::WP4::CCM::Path qw(unescape);

use NCM::Component::Systemd::Service::Unit qw(:targets $DEFAULT_TARGET
    $TYPE_SYSV $TYPE_TARGET $DEFAULT_STARTSTOP $DEFAULT_STATE
    :states);
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


Readonly my $INITTAB => "/etc/inittab"; # meaningless in systemd
Readonly my $DEFAULT_RUNLEVEL => 3; # If inittab has no default set

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

=item log

A logger instance (compatible with C<CAF::Object>).

=back

=item current_units

Return hash reference with current configured units
determined via C<chkconfig --list>.

(No type to specify, C<sysv> type is forced).

=cut

sub current_units
{
    my $self = shift;

    my %current;

    my $data = CAF::Process->new(
        [$CHKCONFIG, '--list'],
        log => $self,
        keeps_state => 1,
        )->output();
    my $ec = $?;
    if ($ec) {
        $self->error("Cannot get list of current units from $CHKCONFIG: ec $ec ($data)");
        return;
    }

    foreach my $line (split(/\n/, $data)) {

        # afs       0:off   1:off   2:off   3:off   4:off   5:off   6:off
        # ignore the "xinetd based services"
        next if ($line !~ m/^([\w\-]+)\s+((?:[0-6]:(?:on|off)(?:\s+|\s*$)){7})/);

        my ($servicename, $levels) = ($1, $2);
        my $detail = {
            shortname => $servicename,
            type => $TYPE_SYSV,
            startstop => $DEFAULT_STARTSTOP
        };

        $detail->{name} = "$detail->{shortname}.$detail->{type}";

        if ($levels =~ m/[0-6]:on/) {
            $self->debug(1, "Found 'on' states for unit $detail->{name}");
            my $ontargets = $self->convert_runlevels(join('', $levels =~ /([0-6]):on/g));
            $detail->{state}   = $STATE_ENABLED;
            $detail->{targets} = $ontargets;
        } else {
            $self->debug(1, "No 'on' states found for unit $detail->{name}");
            # TODO include the runlevel 0,1 and 6 in the off-conversion?
            # if the state is off, targets don't really matter
            my $offtargets = $self->convert_runlevels(join('', $levels =~ /([2-5]):off/g));
            $detail->{state}   = $STATE_DISABLED;
            $detail->{targets} = $offtargets;
        }

        # Does not make much sense for current units, since they are not missing.
        $detail->{possible_missing} = $self->is_possible_missing($detail->{name}, $detail->{state});

        $self->debug(1, "current_units added chkconfig unit $detail->{name}");
        $self->debug(2, "current_units added chkconfig ", $self->unit_text($detail));
        $current{$detail->{name}} = $detail;
    }

    $self->debug(1, "current_units found ", scalar keys %current, " units:",
                 join(",", sort keys %current));
    return \%current;
}

=pod

=item current_target

Return the current target based on legacy C<current_runlevel>.

=cut

sub current_target
{
    my ($self) = @_;

    my $runlevel = $self->current_runlevel();

    my $targets = $self->convert_runlevels($runlevel);
    my $target = @{$targets}[0];

    $self->verbose("Current target $target from current runlevel $runlevel");

    return $target;
}

=pod

=item default_target

Return the default target based on legacy C<default_runlevel>.

=cut

sub default_target
{
    my ($self) = @_;

    my $runlevel = $self->default_runlevel();

    my $targets = $self->convert_runlevels($runlevel);
    my $target = @{$targets}[0];

    $self->verbose("Default target $target from default runlevel $runlevel");

    return $target;
}

=pod

=item configured_units

C<configured_units> parses the C<tree> hash reference and builds up the
units to be configured. It returns a hash reference with key the unit name and
values the details of the unit.

(C<tree> is typically C<$config->getElement('/software/components/chkconfig/service')->getTree>.)

This method converts the legacy states as following

=over

=item del : masked

=item add: disabled

=item off : disabled

=item on : enabled

=item reset: this state is ignored / not supported.

=back

=cut

sub configured_units
{
    my ($self, $tree) = @_;

    my %units;

    while (my ($service, $detail) = each %$tree) {
        # fix the details to reflect new schema

        # all legacy types are assumed to be sysv services
        $detail->{type} = $TYPE_SYSV;

        # set the shortname based on configured name
        $detail->{shortname} = $detail->{name} ? $detail->{name} : unescape($service);

        # Redefine the name to full unit name
        $detail->{name} = "$detail->{shortname}.$detail->{type}";

        my $reset = delete $detail->{reset};
        $self->verbose('Ignore the reset value $reset from unit $detail->{name}') if defined($reset);

        my $on = delete $detail->{on};
        my $off = delete $detail->{off};

        my $leveltxt;
        # off-level precedes on-level (as off state precedes on state)
        if(defined($off)) {
            $leveltxt = $off;
        } elsif(defined($on)) {
            $leveltxt = $on;
        }
        $detail->{targets} = $self->convert_runlevels($leveltxt);

        my $add = delete $detail->{add};
        my $del = delete $detail->{del};
        my $state = $DEFAULT_STATE;
        my $chkstate; # reporting only

        if($del) {
            $state = $STATE_MASKED; # implies off, ignores on/add
            $chkstate = "del";
        } elsif(defined($off)) {
            $state = $STATE_DISABLED; # ignores on, implies add
            $chkstate = "off ('$off')";
        } elsif(defined($on)) {
            $state = $STATE_ENABLED; # implies add
            $chkstate = "on ('$on')";
        } elsif($add) {
            # add gets mapped to off/disabled
            $state = $STATE_DISABLED;
            $chkstate = "add";
        } else {
            # how did we get here?
            $self->error("No valid combination of legacy chkconfig states del/off/on/add found.",
                         "Skipping this unit $detail->{name}.");
            next;
        }

        $self->debug(2, "legacy chkconfig $chkstate set, state is now $state");

        $detail->{state} = $state;

        $detail->{possible_missing} = $self->is_possible_missing($detail->{name}, $detail->{state});

        # startstop mandatory
        $detail->{startstop} = $DEFAULT_STARTSTOP if (! exists($detail->{startstop}));

        $self->debug(1, "Add legacy name $detail->{name} (service $service)");
        $self->debug(2, "Add legacy ", $self->unit_text($detail));
        $units{$detail->{name}} = $detail;

    };

    $self->debug(1, "configured_units found ", scalar keys %units, " units:",
                 join(",", sort keys %units));
    return \%units;

}

=pod

=back

=head2 Private methods

=over

=item is_possible_missing

Determine if C<unit> is C<possible_missing>
(see C<make_cache_alias>). (Returns 0 or 1).

A unit is possible_missing if

=over

=item the unit is in state masked or disabled
(i.e. unit that is not expected to be running anyway).

Other then pure systemd, chkconfig state off always implies
that a disabled service unit is not running.

=back

=cut


sub is_possible_missing
{
    my ($self, $unit, $state) = @_;

    if ($state eq $STATE_DISABLED) {
        $self->debug(1, "Unit $unit with state $STATE_DISABLED is possible_missing in chkconfig");
        return 1;
    }

    return $self->SUPER::is_possible_missing($unit, $state);
}

=pod

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
                $self->debug(1, "Target $1 for level $lvl none of default targets");
            } elsif (!($target eq $1)) {
                $self->debug(1, "Target $1 for level $lvl different from default $target");
            } else {
                $self->debug(1, "Target $1 for level $lvl found.");
            }
            $target = $1;
        } else {
            $id = "<undef>" if (!defined($id));    # handle unitialized value warning
            $self->warn("Unable to identify target for runlevel$lvl.target (Id $id).",
                " Using default target $target for level $lvl.");
        }
        push(@runlevel2target, "$target.$TYPE_TARGET");
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
        $self->generate_runlevel2target();
        if (!@runlevel2target) {
            $self->error("Failed to generate runlevel2target cache");
            return;
        }
    }

    # only keep the relevant ones
    my @targets;
    if (defined($legacylevel)) {
        if ($legacylevel eq "") {
            push(@targets, "$DEFAULT_TARGET.$TYPE_TARGET");
        } else {
            foreach my $lvl (0 .. 6) {
                if ($legacylevel =~ m/$lvl/) {
                    my $target = $runlevel2target[$lvl];
                    push(@targets, $target) if (!grep {$_ eq $target} @targets);
                }
            }
        }

        # only for non-default/non-valid runlevels?
        if (!scalar @targets) {
            $self->warn("legacylevel set to $legacylevel, but not converted in ",
                        "new targets. Using default $DEFAULT_TARGET.");
            push(@targets, "$DEFAULT_TARGET.$TYPE_TARGET");
        }
        $self->debug(1, "Converted legacylevel '$legacylevel' in " . join(', ', @targets));
    } else {
        $self->debug(1, "legacylevel undefined, using default $DEFAULT_TARGET");
        push(@targets, "$DEFAULT_TARGET.$TYPE_TARGET");
    }

    return \@targets;
}

=pod

=item default_runlevel

C<default_runlevel> returns the default runlevel
via the INITTAB file. If that fails, the default
DEFAULT_RUNLEVEL is returned.

=cut

sub default_runlevel
{
    my $self = shift;

    my $defaultrunlevel = $DEFAULT_RUNLEVEL;

    my $inittab = CAF::FileReader->new($INITTAB);
    if ("$inittab" =~ m/^[^:]*:(\d):initdefault:/m) {
        $defaultrunlevel = $1;
        $self->verbose("Found initdefault $defaultrunlevel set in inittab $INITTAB");
    } else {
        $self->verbose("No initdefault set in inittab $INITTAB; using default legacy runlevel $defaultrunlevel");
    }

    return $defaultrunlevel;
}

=pod

=item current_runlevel

Return the current legacy runlevel.

The rulevel is determined by trying (in order)
C</sbin/runlevel> or C<who -r>. If both fail, the
C<default_runlevel> method is called and its value
is returned.

=cut

sub current_runlevel
{
    my $self = shift;

    my $process = sub {
        my ($self, $cmd, $reg) = @_;
        my $proc = CAF::Process->new($cmd, log => $self, keeps_state => 1);
        if (! $proc->is_executable) {
            $self->debug(1, "No runlevel via command $proc (not executable)");
            return;
        }

        my $line = $proc->output();
        my $ec = $?;
        my $level;
        if ($line && $line =~ m/$reg/m) {
            $level = $1;
            $self->verbose("Current runlevel from command $proc is $level");
        } else {
            # happens at install time
            $self->warn("Cannot get runlevel from command $proc: $line (exitcode $ec).");
        }
        return $level
    };

    # output: N 5
    my $level = &$process($self, ["/sbin/runlevel"], qr{^\w+\s+(\d+)\s*$});
    return $level if (defined($level));

    # output:         run-level 5  Feb 19 16:08                   last=S
    $level = &$process($self, ["/usr/bin/who", "-r"], qr{^\s*run-level\s+(\d+)\s});
    return $level if (defined($level));

    # different from ncm-chkconfig:
    #   doesn't return undef if commands produce invalid output
    $level = $self->default_runlevel();
    $self->verbose("Returning default runlevel $level (other commands unavailable/failed)");
    return $level;
}

=pod

=back

=cut

1;
