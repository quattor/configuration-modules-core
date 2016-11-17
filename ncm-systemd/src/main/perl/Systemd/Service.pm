# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::Service;

use 5.10.1;
use strict;
use warnings;

use parent qw(CAF::Object Exporter);

use NCM::Component::Systemd::Service::Chkconfig;
use NCM::Component::Systemd::Service::Unit qw(:states :types);
use NCM::Component::Systemd::Systemctl qw(systemctl_command_units);

use LC::Exception qw (SUCCESS);

use Readonly;

# these won't be turned off with default settings
# TODO add some systemd services? systemd itself? rc.local?
# TODO protecting network assumes ncm-network is being used
# TODO shouldn't these services be "always on"?
Readonly::Hash my %DEFAULT_PROTECTED_SERVICES => (
    network => 1,
    messagebus => 1,
    haldaemon => 1,
    sshd => 1,
);

Readonly my $BASE => "/software/components/systemd";
Readonly my $LEGACY_BASE => "/software/components/chkconfig";

Readonly our $UNCONFIGURED_DISABLED => $STATE_DISABLED;
Readonly our $UNCONFIGURED_ENABLED => $STATE_ENABLED;
Readonly our $UNCONFIGURED_IGNORE => 'ignore';
Readonly our $UNCONFIGURED_MASKED => $STATE_MASKED;

Readonly my $UNMASK => 'unmask';

Readonly::Array my @UNCONFIGURED => qw(
    $UNCONFIGURED_DISABLED $UNCONFIGURED_ENABLED
    $UNCONFIGURED_IGNORE $UNCONFIGURED_MASKED
    );

Readonly::Array my @UNCONFIGURED_SUPPORTED => (
    $UNCONFIGURED_DISABLED, $UNCONFIGURED_ENABLED,
    $UNCONFIGURED_IGNORE, $UNCONFIGURED_MASKED,
    );

our @EXPORT_OK = qw();
push @EXPORT_OK, @UNCONFIGURED;

our %EXPORT_TAGS = (
    unconfigured => \@UNCONFIGURED,
);

# The default w.r.t. handling unconfigured units.
my $unconfigured_default = $UNCONFIGURED_IGNORE;

=pod

=head1 NAME

NCM::Component::Systemd::Service handles the C<ncm-systemd> units.

=head2 Public methods

=over

=item new

Returns a new object, accepts the following options

=over

=item log

A logger instance (compatible with C<CAF::Object>).

=back

=cut

sub _initialize
{
    my ($self, %opts) = @_;

    $self->{log} = $opts{log} if $opts{log};

    $self->{unit} = NCM::Component::Systemd::Service::Unit->new(log => $self);
    $self->{chkconfig} = NCM::Component::Systemd::Service::Chkconfig->new(log => $self);

    return SUCCESS;
}

=pod

=item configure

C<configure> gathered the to-be-configured units from the C<config> using the
C<gather_units> method and then takes appropriate actions.

=cut

sub configure
{
    my ($self, $config) = @_;

    $self->set_unconfigured_default($config);

    my $configured = $self->gather_configured_units($config);

    my $current = $self->gather_current_units($configured);

    my ($states, $acts) = $self->process($configured, $current);

    $self->change($states, $acts);

    if ($unconfigured_default ne $UNCONFIGURED_IGNORE) {
        $self->error("Support for default unconfigured behaviour ",
                     "$unconfigured_default is not implemented yet. ",
                     "(Schema/component version mismatch?)");
    }
}


=pod

=back

=head2 Private methods

=over

=item set_unconfigured_default

Set the default behaviour for unconfigured units from C<ncn-systemd>
and legacy C<ncm-chkconfig>.

=cut

sub set_unconfigured_default
{
    my ($self, $config)= @_;

    my $path = {
        unit => "$BASE/unconfigured",
        chkconfig => "$LEGACY_BASE/default",
    };

    # map legacy values to new ones
    my $chkconfig_map = {
        off => $UNCONFIGURED_DISABLED,
        ignore => $UNCONFIGURED_IGNORE,
    };

    # TODO add code to select.
    my $pref = 'unit';
    my $other = 'chkconfig';

    my $found;
    if($config->elementExists($path->{$pref})) {
        $found = $pref;
    } elsif ($config->elementExists($path->{$other})) {
        $found = $other;
    } else {
        # This should never happen since it's mandatory in ncm-systemd schema
        $self->info("Default not defined for preferred $pref or other $other. ",
                    "Current value is $unconfigured_default");
    }

    if ($found) {
        my $val = $config->getElement($path->{$found})->getValue();
        if ($found eq 'chkconfig') {
            # configure the legacy value
            $self->verbose("Converting legacy unconfigured_default ",
                           "value $val to ", $chkconfig_map->{$val});
            $val = $chkconfig_map->{$val};
        }
        $unconfigured_default = $val;
        $self->verbose("Set unconfigured_default to $unconfigured_default ",
                       "using $found path ", $path->{$found});
    }

    if (! (grep {$_ eq $unconfigured_default} @UNCONFIGURED_SUPPORTED)) {
        # Should be forced by schema (but now 2 schemas)
        $self->error("Unsuported value $unconfigured_default; ",
                     "setting it to $UNCONFIGURED_IGNORE.");
        $unconfigured_default = $UNCONFIGURED_IGNORE;
    }

    # For unittesting only
    return $unconfigured_default;
}

=pod

=item gather_configured_units

Gather the list of all configured units from both C<ncm-systemd>
and legacy C<ncm-chkconfig> location, and take appropriate actions.

For any unit defined in both C<ncm-systemd> and C<ncm-chkconfig> location,
the C<ncm-systemd> settings will be used.

Returns a hash reference with key the unit name and value the unit detail.

=cut

# small wrapper to get the configuration tree
# returns undef if path doesn't exist
# convert the tree for a unit in appropriate form for unitfile configuration
sub _get_tree
{
    my ($self, $config, $src) = @_;

    return if (! $config->elementExists($src->{path}));

    my $tree;

    if ($src->{type} eq 'unit') {
        $tree = $src->{instance}->_getTree($config, $src->{path});
    } else {
        $tree = $config->getTree($src->{path});
    }

    return $tree;
}

sub gather_configured_units
{
    my ($self, $config) = @_;

    my $chkconfig = {
        path => "$LEGACY_BASE/service",
        instance => $self->{chkconfig},
        type => 'chkconfig',
    };

    my $unit = {
        path => "$BASE/unit",
        instance => $self->{unit},
        type => 'unit',
    };

    # TODO: add code to select which one is preferred.
    my $pref = $unit;
    my $other = $chkconfig;

    my $units = {};

    # Gather the other units first (if any)
    my $tree = $self->_get_tree($config, $other);
    if ($tree) {
        $units = $other->{instance}->configured_units($tree);
    }

    # Update with preferred units (if any)
    $tree = $self->_get_tree($config, $pref);
    if ($tree) {
        my $new_units = $pref->{instance}->configured_units($tree);
        while (my ($unit, $detail) = each %$new_units) {
            if ($units->{$unit}) {
                $self->info("Found configured unit $unit via preferred $pref->{path} ",
                            "and non-preferred $other->{path}. Using preferred unit details.");
            }
            $units->{$unit} = $detail;
        }
    }

    $self->verbose("Gathered ", scalar keys %$units, " configured units: ",
                   join(", ", sort keys %$units));

    return $units;
}

=pod

=item gather_current_units

Gather list of current units from both C<systemctl> and legacy C<chkconfig>
using resp. C<unit> and C<chkconfig> C<current_units> methods.

The hashref C<relevant_units> is used to run minimal set
of system commands where possible: e.g. if the hashref represents the
configured units and if C<unconfigured_default> is C<ignore>, only gathered
details for these units.

=cut

sub gather_current_units
{
    my ($self, $relevant_units) = @_;

    my @limit_units;
    my $possible_missing;
    # Also include all unconfigured units in the queries.
    if($unconfigured_default ne $UNCONFIGURED_IGNORE) {
        $self->verbose("Unconfigured default $unconfigured_default, ",
                       "taking all possible units into account");
    } else {
        @limit_units = sort keys %$relevant_units;
        $self->verbose("Unconfigured default $unconfigured_default, ",
                       "using ", scalar @limit_units," limit units: ",
                       join(',',@limit_units));
        $possible_missing = $self->{unit}->possible_missing($relevant_units);
    }

    # A sysv service that is not listed in chkconfig --list
    #   you can run systemctl enable/disable on it (it gets redirected to chkconfig)
    #   they do show up in list-units --all
    #     even when only chkconfig --add is used
    #   systemctl mask removes it from the output of chkconfig --list
    #   systemctl unmask restores it to last known state

    # How to join these:
    # TODO: re-verify (seems not to be the case?)
    #   The only units that are not seen by systemctl are SYSV services that
    #   are not started via systemd (not necessarily running).
    #   The 'chkconfig --list' is the only command not properly handled in EL7 systemd.
    # TODO: what if someone starts a SYSV service via /etc/init.d/myservice start?
    #   Does systemd see this? (and how would it do that?)

    my $units = $self->{chkconfig}->current_units();

    # Add all found chkconfig services to the limit_units
    # (unless limit_units is undefined/empty, in which case all units are gathered)
    if(@limit_units) {
        foreach my $unit (sort keys %$units) {
            push(@limit_units, $unit) if (! (grep {$_ eq $unit} @limit_units));
        }
    }
    my $current_units = $self->{unit}->current_units(\@limit_units, $possible_missing);

    # It's normal that systemctl finds the chkconfig units;
    # the other way around should not occur.
    foreach my $unit (keys %$units) {
        if (! $current_units->{$unit}) {
            $self->warn("Found current unit $unit via Chkconfig but is not in Unit. ",
                        "(This is unexpected, please notify the developers)");
        }
    }

    while (my ($unit, $detail) = each %$current_units) {
        if ($units->{$unit}) {
            # TODO: Do we compare them to see if both are the same details or simply trust Unit?
            $self->verbose("Found current unit $unit via Chkconfig and Unit. ",
                           "Using Unit unit details.");
        }
        $units->{$unit} = $detail;
    }

    $self->verbose("Gathered ", scalar keys %$units, " current units: ",
                   join(", ", sort keys %$units));

    return $units;
}

=pod

=item process

C<process> the C<configured> units and
retrun hash references with state and activation changes.

It uses the C<current> units to make the required decisions.

(Unconfigured units are not dealt with in this method).

=cut

# TODO: move to Unit?
# TODO: handle targets (current code only deals with state and active)

sub process
{
    my ($self, $configured, $current) = @_;

    # actions to take

    # masked:
    #   mask, stop if running and startstop
    #     first mask, then stop (e.g. autorestart units)
    #     or first disable, then mask, then stop if running?
    #   replaces /etc/systemd/system/$unit.$type with symlink to /dev/null
    #     TODO: check what happens when also /etc/systemd/system/$unit.$type.d/X.cfg exists
    # disabled:
    #   disable, stop if running and startstop
    # enabled:
    #   unmask, enable, start if not running and startstop
    #     unmask only if masked?
    #   check if targets are ok
    #     TODO: how do we disable certain targets of particular unit?
    #     TODO: what to do with unconfigured targets?

    # 0 means stop/should-not-be-running
    # 1 means start/should-be-running
    my $actmap = {
        $STATE_ENABLED => 1,
        $STATE_DISABLED => 0,
        $STATE_MASKED => 0,
    };

    my $acts = {
        0 => [],
        1 => [],
    };

    my $states = {
        $STATE_ENABLED => [],
        $STATE_DISABLED => [],
        $STATE_MASKED => [],
        $UNMASK => [],
    };

    # Cache should be filled by the current_units call
    #   in gather_current_units method
    my @configured = sort keys %$configured;

    # Possible missing units shouldn't raise errors
    my $possible_missing = $self->{unit}->possible_missing($configured);

    my $aliases = $self->{unit}->get_aliases(\@configured, possible_missing => $possible_missing);

    foreach my $unit (sort @configured) {
        my $detail = $configured->{$unit};

        my $realname = $aliases->{$unit};
        if ($realname) {
            my $msg = "Configured unit $unit is an alias of";
            if($configured->{$realname}) {
                $self->error("$msg configured unit $realname. Skipping the alias configuration. ",
                             "(This is a configuration issue.)");
                next;
            } else {
                $self->verbose("$msg non-configured unit $realname.");
                $unit = $realname;
            }
        }

        my $state = $detail->{state};
        my $expected_act = $actmap->{$state};

        my $cur = $current->{$unit};

        my $addstate = 1;
        my $addact = $detail->{startstop};

        my $msg = '';
        if ($cur) {
            # only if state is not what you wanted
            $addstate = ! $self->{unit}->is_ufstate($unit, $state);

            if ($addact) {
                my $current_act = $self->{unit}->is_active($unit);
                $addact = ! (defined($current_act) && ($expected_act eq $current_act));
                $self->debug(1, "process: expected activation $expected_act current activation ",
                             defined($current_act) ? $current_act : "<undef>",
                             " : adding for (de)activation $addact");
            }
        } else {
            my $nocur_msg = "process: no current details found for unit $unit";
            if (grep {$_ eq $unit} @$possible_missing) {
                # We can safely assume we didn't forget to update the cache, so there unit is not here.
                # There's no point in triggering any action or state change.
                $addstate = 0;
                $addact = 0;
                $self->debug(1, "$nocur_msg which is in possible_missing. ",
                             "Assuming it is truly missing and thus ",
                             "not forcing state $state nor (de)activation.");
            } else {
                # Forcing the state and action
                $self->debug(1, "$nocur_msg. Forcing state $state and (de)activation.");
                $msg .= "forced ";
            }
        }

        if ($addstate) {
            push(@{$states->{$state}}, $unit);
            $msg .= "state $state";
            # masked units have to be unmasked before state change
            if ($self->{unit}->is_ufstate($unit, $STATE_MASKED)) {
                push(@{$states->{$UNMASK}}, $unit);
                $msg .= " (requires $UNMASK)";
            };
        }
        if ($addact) {
            push(@{$acts->{$expected_act}}, $unit);
            $msg .= ($expected_act ? '' : 'de') . "activation";
        }
        $self->verbose($msg ? "process: unit $unit scheduled for $msg" :
                              "process: nothing to do for unit $unit");
    }

    return ($states, $acts);
};

=pod

=item change

Actually make the changes as specified in
the hashrefs C<states> and C<acts> (which hold the
changes to be made to resp. the state and the activity
of the units).

=cut

sub change
{

    my ($self, $states, $acts) = @_;

    # Make changes
    #  1st set the new state
    #    to prevent autorestart units from restarting
    #  2nd (de)activate

    my $change_state = {
        $STATE_ENABLED => 'enable',
        $STATE_DISABLED => 'disable',
        $STATE_MASKED => 'mask',
        $UNMASK => $UNMASK,
    };

    my $change_activation = {
        0 => 'stop',
        1 => 'start',
    };

    # TODO What order is best? enable before disable?
    # Unmask before enable/disable a previously masked unit
    foreach my $state (($UNMASK, $STATE_MASKED, $STATE_DISABLED, $STATE_ENABLED)) {
        my @units = @{$states->{$state}};

        # TODO: process units wrt dependencies?
        if (@units) {
            # TODO: trap exitcode and stop any further processing in case of error?
            # CAF::Process logger is sufficient
            systemctl_command_units($self, $change_state->{$state}, @units);
        }
    }

    # TODO: same TODOs as with states
    foreach my $act (sort keys %$acts) {
        my @units = @{$acts->{$act}};

        # TODO: process units wrt dependencies?
        if (@units) {
            # TODO: trap exitcode and stop any further processing in case of error?
            # CAF::Process logger is sufficient
            systemctl_command_units($self, $change_activation->{$act}, @units);
        }
    }

}


=pod

=back

=cut

1;
