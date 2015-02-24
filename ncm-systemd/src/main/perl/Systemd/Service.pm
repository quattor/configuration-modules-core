# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::Service;

use 5.10.1;
use strict;
use warnings;

use parent qw(CAF::Object Exporter);

use NCM::Component::Systemd::Service::Unit qw(:states :types);
use NCM::Component::Systemd::Service::Chkconfig;

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

Readonly my $BASE => "/software/components/${project.artifactId}";
Readonly my $LEGACY_BASE => "/software/components/chkconfig";

Readonly our $UNCONFIGURED_IGNORE => 'ignore';
Readonly our $UNCONFIGURED_DISABLED => $STATE_DISABLED;
Readonly our $UNCONFIGURED_ENABLED => $STATE_ENABLED;
Readonly our $UNCONFIGURED_MASKED => $STATE_MASKED;

Readonly::Array my @UNCONFIGURED => qw($UNCONFIGURED_IGNORE
    $UNCONFIGURED_DISABLED $UNCONFIGURED_ENABLED $UNCONFIGURED_MASKED);

our @EXPORT_OK = qw();
push @EXPORT_OK, @UNCONFIGURED;

our %EXPORT_TAGS = (
    unconfigured => \@UNCONFIGURED,
);

# The default w.r.t. handling unconfigured services.
my $unconfigured_default = $UNCONFIGURED_IGNORE;

=pod

=head1 NAME

NCM::Component::Systemd::Service handles the C<ncm-systemd> services.

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

C<configure> gathered the to-be-configured services from the C<config> using the
C<gather_services> method and then takes appropriate actions.

=cut

sub configure
{
    my ($self, $config) = @_;

    $self->set_unconfigured_default($config);

    my $configured = $self->gather_configured_services($config);

    my $current = $self->gather_current_services(keys %$configured);

    $self->process($configured, $current);

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

Set the default behaviour for unconfigured services from C<ncn-systemd>
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
        $self->info("Default not defined for preferred $pref or other $other. Current value is $unconfigured_default");
    }

    my $val = $config->getElement($path->{$found})->getValue();
    if ($found eq 'chkconfig') {
        # configure the legacy value
        $self->verbose("Converting legacy unconfigured_default value $val to ", $chkconfig_map->{$val});
        $val = $chkconfig_map->{$val};
    }
    $unconfigured_default = $val;
    $self->verbose("Set unconfigured_default to $unconfigured_default using $found path ", $path->{$found});

    if (! (grep {$_ eq $unconfigured_default} @UNCONFIGURED)) {
        # Should be forced by schema (but now 2 schemas)
        $self->error("Unssuported value $unconfigured_default; setting it to $UNCONFIGURED_IGNORE");
        $unconfigured_default = $UNCONFIGURED_IGNORE;
    }

    # For unittesting only
    return $unconfigured_default;
}

=pod

=item gather_configured_services

Gather the list of all configured services from both C<ncm-systemd>
and legacy C<ncm-chkconfig> location, and take appropriate actions.

For any service defined in both C<ncm-systemd> and C<ncm-chkconfig> location,
the C<ncm-systemd> settings will be used.

Returns a hash reference with key the service name and value the service detail.

=cut

sub gather_configured_services
{
    my ($self, $config) = @_;

    my $chkconfig = {
        path => "$LEGACY_BASE/service",
        instance => $self->{chkconfig},
    };

    my $unit = {
        path => "$BASE/service",
        instance => $self->{unit},
    };

    # TODO: add code to select which one is preferred.
    my $pref = $unit;
    my $other = $chkconfig;

    my $services = {};

    # Gather the other services first (if any)
    if ($config->elementExists($other->{path})) {
        my $tree = $config->getElement($other->{path})->getTree();
        $services = $other->{instance}->configured_services($tree);
    }

    # Update with preferred services (if any)
    if ($config->elementExists($pref->{path})) {
        my $tree = $config->getElement($pref->{path})->getTree();
        my $new_services = $pref->{instance}->configured_services($tree);
        while (my ($service, $detail) = each %$new_services) {
            if ($services->{$service}) {
                $self->info("Found configured service $service via preferred $pref->{path} ",
                            "and non-preferred $other->{path}. Using preferred service details.");
            }
            $services->{$service} = $detail;
        }
    }

    $self->verbose("Gathered ", scalar keys %$services, " configured services: ",
                   join(", ", sort keys %$services));

    return $services;
}

=pod

=item gather_current_services

Gather list of current services from both C<systemctl> and legacy C<chkconfig>
using resp. C<unit> and C<chkconfig> C<current_services> methods.

All arguments form a list of C<relevant_services> that is used to run minimal set
of system commands (and only if C<unconfigured_default> is C<ignore>).

=cut

sub gather_current_services
{
    my ($self, @relevant_services) = @_;

    # Also include all unconfigured services in the queries.
    if($unconfigured_default ne $UNCONFIGURED_IGNORE) {
        $self->verbose("Unconfigured default $unconfigured_default, ",
                       "taking all possible services into account");
        @relevant_services = undef;
    } else {
        $self->verbose("Unconfigured default $unconfigured_default, ",
                       "using ", scalar @relevant_services," relevant services: ",
                       join(',',@relevant_services));
    }

    # A sysv service that is not listed in chkconfig --list
    #   you can run systemctl enable/disable on it (it gets redirected to chkconfig)
    #   they do show up in list-units --all
    #     even when only chkconfig --add is used
    #   systemctl mask removes it from the output of chkconfig --list
    #   systemctl umask restores it to last known state

    # How to join these:
    # TODO: re-verify (seems not to be the case?)
    #   The only services that are not seen by systemctl are SYSV services that
    #   are not started via systemd (not necessarily running).
    #   The 'chkconfig --list' is the only command not properly handled in EL7 systemd.
    # TODO: what if someone starts a SYSV service via /etc/init.d/myservice start?
    #   Does systemd see this? (and how would it do that?)

    my $services = $self->{chkconfig}->current_services();

    my $current_units = $self->{unit}->current_services(@relevant_services);
    while (my ($service, $detail) = each %$current_units) {
        if ($services->{$service}) {
            # TODO: Do we compare them to see if both are the same details or simply trust Unit?
            $self->info("Found configured service $service via Chkconfig and Unit. ",
                        "Using Unit service details.");
        }
        $services->{$service} = $detail;
    }

    $self->verbose("Gathered ", scalar keys %$services, " current services: ",
                   join(", ", sort keys %$services));

    return $services;
}

=pod

=item process

C<process> the C<configured> services and
take required action and/or make configuration changes.
It uses the C<current> services to make the required decisions.

(Unconfigured services are not dealt with in this method).

=cut

sub process
{
    my ($self, $configured, $current) = @_;

    # actions to take

    # masked:
    #   mask, stop if running and startstop
    #     first mask, then stop (e.g. autorestart services)
    #     or first disable, then mask, then stop if running?
    #   replaces /etc/systemd/system/$unit.$type with symlink to /dev/null
    #     TODO: check what happens when also /etc/systemd/system/$unit.$type.d/X.cfg exists
    # disabled:
    #   disable, stop if running and startstop
    # enabled:
    #   unmask, enable, start if not running and startstop
    #     unmask only if masked?
    #   check if targets are ok
    #     TODO: how do we disable certain targets of particular service?
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
    };

    # Cache should be filled by the current_services call 
    #   in gather_current_services method
    my @configured = keys %$configured;
    my $aliases = $self->{unit}->get_aliases(\@configured);

    foreach my $unit (sort @configured) {
        my $detail = $configured->{$unit};

        my $realname = $aliases->{$unit};
        if($realname) {
            my $msg = "Configured unit $unit is an alias of";
            if($configured->{$realname}) {
                $self->error("$msg configured unit $realname. Skipping the alias configuration. ",
                             "(This is a configuration issue.)");
                next;
            } else {
                $self->debug("Configured unit $unit is an alias of non-configured unit $realname.");
            }
        }

        my $state = $detail->{state};
        my $type = $detail->{type};
        my $fun = $detail->{fullname};
        my $expected_act = $actmap->{$state};

        my $cur = $current->{$unit};

        my $addstate = 1;
        my $addact = $detail->{startstop};

        my $msg = '';
        if ($cur) {
            # only if state is not what you wanted
            $addstate = ! $self->{unit}->is_ufstate($unit, $state, type => $type);

            if ($addact) {
                my $current_act = $self->{unit}->is_active($unit, type => $type);
                $addact = $expected_act != $current_act;
                $self->debug(1, "process: expected activation $expected_act current activation $current_act: ",
                             "adding for (de)activation $addact");
            }
        } else {
            # Forcing the state and action
            $self->debug(1, "process: no current details found for unit $unit. Forcing state $state and (de)activation");
            $msg .= "forced ";
        }

        if ($addstate) {
            push(@{$states->{$state}}, $fun);
            $msg .= "state $state";
        }
        if ($addact) {
            push(@{$acts->{$expected_act}}, $fun);
            $msg .= ($expected_act ? '' : 'de') . "activation";
        }
        $self->verbose($msg ? "process: unit $unit scheduled for $msg" :
                              "process: nothing to do for unit $unit");
    }

    # For unittests
    return $states, $acts;
}


=pod

=back

=cut

1;
