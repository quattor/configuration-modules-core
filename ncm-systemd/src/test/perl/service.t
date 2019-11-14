use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Quattor qw(service_services service_ceph021);

use helper;
use NCM::Component::Systemd::Service qw(:unconfigured);
use NCM::Component::Systemd::Service::Unit qw(:types :states);
use NCM::Component::Systemd::Systemctl qw($SYSTEMCTL);
use NCM::Component::systemd;

$CAF::Object::NoAction = 1;

# need a logger instance (could also use CAF::Object instance)
my $cmp = NCM::Component::systemd->new('systemd');

my $cfg = get_config_for_profile('service_services');

=pod

=head1 DESCRIPTION

Test C<NCM::Component::Systemd::Service> module for systemd.

=cut

my $svc = NCM::Component::Systemd::Service->new($cmp->prefix, log => $cmp);
isa_ok($svc, "NCM::Component::Systemd::Service",
       "Created a NCM::Component::Systemd::Service instance");
isa_ok($svc->{unit}, "NCM::Component::Systemd::Service::Unit",
       "Has a NCM::Component::Systemd::Service::Unit instance");
isa_ok($svc->{chkconfig}, "NCM::Component::Systemd::Service::Chkconfig",
       "Has a NCM::Component::Systemd::Service::Chkconfig instance");
is($svc->{BASE}, "/software/components/systemd", "systemd configuration path");

=pod

=head2 exported constants

=cut

my $unconfs = [
    $UNCONFIGURED_DISABLED, $UNCONFIGURED_ENABLED,
    $UNCONFIGURED_OFF, $UNCONFIGURED_ON,
    $UNCONFIGURED_IGNORE,
];
is_deeply($unconfs, [qw(disabled enabled off on ignore)],
          "exported UNCONFIGURED states");

=pod

=head2 set_unconfigured_default

Test set_unconfigured_default

=cut

# Only tests the systemd setting.
$cmp->{ERROR} = 0;
is($svc->set_unconfigured_default($cfg), $UNCONFIGURED_IGNORE,
    "Set unconfigured to ignore");
is($cmp->{ERROR}, 0, "No errors logged");

=pod

=head2 gather_configured_services

Test gather_configured_services

=cut

my $mockuf = Test::MockModule->new('NCM::Component::Systemd::UnitFile');
my @uf_write;
$mockuf->mock("write", sub {
    my $self = shift;
    # also tested by the getTree call
    isa_ok($self->{config}, 'EDG::WP4::CCM::CacheManager::Element',
           "config on write for $self->{unit} is an Element instance");
    push(@uf_write, [$self->{unit}, $self->{replace}, $self->{backup}, $self->{config}->getTree(), $self->{custom}]);
    return 1;
});

my $gathered_configured_units = $svc->gather_configured_units($cfg);
#diag explain $gathered_configured_units;
is_deeply($gathered_configured_units, {
    'test_on.service' => {
        name => "test_on.service",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['rescue.target', 'multi-user.target'],
        type => $TYPE_SYSV,
        shortname => "test_on",
        possible_missing => 0,
    },
    'test_add.service' => {
        name => "test_add.service",
        startstop => 1,
        state => $STATE_DISABLED,
        targets => ['multi-user.target'],
        type => $TYPE_SYSV,
        shortname => "test_add",
        possible_missing => 1,
    },
    'othername.service' => {
        name => "othername.service",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['multi-user.target'],
        type => $TYPE_SYSV,
        shortname => "othername",
        possible_missing => 0,
    },
    'test2_on.service' => {
        name => "test2_on.service",
        state => $STATE_ENABLED,
        targets => ["rescue.target", "multi-user.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "test2_on",
        possible_missing => 0,
    },
    'test2_add.target' => {
        name => "test2_add.target",
        state => $STATE_DISABLED,
        targets => ["multi-user.target"],
        startstop => 1,
        type => $TYPE_TARGET,
        shortname => "test2_add",
        possible_missing => 0,
    },
    'othername2.service' => {
        name => "othername2.service",
        state => $STATE_ENABLED,
        targets => ["multi-user.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "othername2",
        possible_missing => 0,
    },
    'test_4_no_restart.service' => {
        name => "test_4_no_restart.service",
        state => $STATE_ENABLED,
        targets => ["multi-user.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "test_4_no_restart",
        possible_missing => 0,
    },
    'test_off.service' => { # from ncm-systemd
        name => "test_off.service",
        state => $STATE_MASKED,
        targets => ["rescue.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "test_off",
        possible_missing => 1,
    },
    'test_del.service' => { # from ncm-systemd
        name => "test_del.service",
        state => $STATE_ENABLED,
        targets => ["rescue.target"],
        startstop => 0,
        type => $TYPE_SERVICE,
        shortname => "test_del",
        possible_missing => 0,
    },
}, "gathered configured units is a union of ncm-systemd and ncm-chkconfig units");

# the configured othername2 is a renamed unit, this also shows that the unit->name is used for unitfilename
is_deeply(\@uf_write, [
              ['othername2.service', 1, '.old', {service => {some1 => "data1"}}, {a1 => 'b1'}],
              ['test3_only.service', 0, '.old', {service => {some => "data"}}, {a => 'b'}],
              ['test_4_no_restart.service', 1, '.old', {service => {some1 => "data1"}, unit => {RefuseManualStart => 1}}, {a1 => 'b1'}],
          ], "configured unitfiles initialized as expected");

# the entries in uf_write show that these have a file/ subtree
ok($gathered_configured_units->{$uf_write[0]->[0]}, "service with file/only=0 is added as configured unit");
ok(! defined($gathered_configured_units->{$uf_write[0]->[1]}),
   "service with file/only=1 is not added to the configured units");

=pod

=head2 gather_current_units

Test gather_current_units

=cut

# this is from ceph021
set_output("chkconfig_list_el7");
use cmddata::service_systemctl_list_show_gen_full_el7_ceph021_load;

# set cups masked: bad ufstate and masked is-enabled
$cmddata::cmds{'gen_full_el7_ceph021_systemctl_is_enabled_cups.service_unit-files'}{out} = "masked\n";
$cmddata::cmds{'gen_full_el7_ceph021_systemctl_show_cups.service_unit-files'}{out} =~ s/^UnitFileState=.*$/UnitFileState=bad/m;
set_output('gen_full_el7_ceph021_systemctl_show_cups.service_unit-files');
set_output('gen_full_el7_ceph021_systemctl_is_enabled_cups.service_unit-files');

$cfg = get_config_for_profile('service_ceph021');

my $configured = $svc->gather_configured_units($cfg, $UNCONFIGURED_IGNORE);
is_deeply($configured->{'network.service'}, { # sysv, on
    name => "network.service",
    startstop => 1,
    state => $STATE_ENABLED,
    targets => ['multi-user.target', 'graphical.target'],
    type => $TYPE_SERVICE,
    shortname => "network",
    possible_missing => 0,
}, "configured network service for ceph021");

is_deeply($configured->{'netconsole.service'}, { # sysv, off
    name => "netconsole.service",
    startstop => 1,
    state => $STATE_ENABLED,
    targets => ['multi-user.target'],
    type => $TYPE_SERVICE,
    shortname => "netconsole",
    possible_missing => 0,
}, "configured netconsole service for ceph021");

is_deeply($configured->{'cups.service'}, { # systemd
    name => "cups.service",
    startstop => 0,
    state => $STATE_DISABLED,
    targets => ['graphical.target'],
    type => $TYPE_SERVICE,
    shortname => "cups",
    possible_missing => 0,
}, "configured cups service for ceph021");

is_deeply($configured->{'rbdmap.service'}, { # sysv, not in chkconfig
    name => "rbdmap.service",
    startstop => 1,
    state => $STATE_ENABLED,
    targets => ['multi-user.target'],
    type => $TYPE_SERVICE,
    shortname => "rbdmap",
    possible_missing => 0,
}, "configured rbdmap service for ceph021");

# not installed, and we don't want it running
is_deeply($configured->{'missing_masked.service'}, {
    name => "missing_masked.service",
    startstop => 1,
    state => $STATE_MASKED,
    targets => ['multi-user.target'],
    type => $TYPE_SERVICE,
    shortname => "missing_masked",
    possible_missing => 1,
}, "missing and masked ceph021");

# not installed, but we want it disabled (should log error)
is_deeply($configured->{'missing_disabled.service'}, {
    name => "missing_disabled.service",
    startstop => 1,
    state => $STATE_DISABLED,
    targets => ['multi-user.target'],
    type => $TYPE_SERVICE,
    shortname => "missing_disabled",
    possible_missing => 0,
}, "missing and disabled ceph021");

# not installed, but we want it disabled (should log error)
is_deeply($configured->{'missing_disabled_chkconfig.service'}, {
    name => "missing_disabled_chkconfig.service",
    startstop => 1,
    state => $STATE_DISABLED,
    targets => ['multi-user.target'],
    type => $TYPE_SERVICE,
    shortname => "missing_disabled_chkconfig",
    possible_missing => 1,
}, "missing and disabled chkconfig ceph021");

# installed, disabled, and not active
is_deeply($configured->{'NetworkManager.service'}, {
    name => "NetworkManager.service",
    startstop => 1,
    state => $STATE_DISABLED,
    targets => ['multi-user.target'],
    type => $TYPE_SERVICE,
    shortname => "NetworkManager",
    possible_missing => 1, # this is a chkconfig one
}, "NetworkManager chkconfig ceph021");

$cmp->{ERROR} = 0;
my $current = $svc->gather_current_units($configured, $UNCONFIGURED_IGNORE);
is($cmp->{ERROR}, 1, "1 error logged (due to missing_disabled service)");

# cdp-listend, ceph, cups, ncm-cdispd, netconsole, network, NetworkManager
# two of them is from the systemd units (cups,NetworkManager)
# the others are from chkconfig --list
is_deeply(scalar keys %$current, 11, "Got 11 current units");

is_deeply($current->{'network.service'}, { # sysv
        name => "network.service",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['multi-user.target', 'graphical.target'],
        type => $TYPE_SERVICE,
        shortname => "network",
        possible_missing => 0,
}, "current network service for ceph021");

is_deeply($current->{'netconsole.service'}, { # sysv
        name => "netconsole.service",
        startstop => 1,
        state => $STATE_DISABLED,
        targets => [],
        type => $TYPE_SERVICE,
        shortname => "netconsole",
        possible_missing => 0,
}, "current netconsole service for ceph021");

is_deeply($current->{'cups.service'}, { # systemd
        name => "cups.service",
        startstop => 1,
        state => $STATE_MASKED,
        targets => [],
        type => $TYPE_SERVICE,
        shortname => "cups",
        possible_missing => 1,
}, "current cups service for ceph021");

is_deeply($current->{'NetworkManager.service'}, { # systemd
        name => "NetworkManager.service",
        startstop => 1,
        state => $STATE_DISABLED,
        targets => [],
        type => $TYPE_SERVICE,
        shortname => "NetworkManager",
        possible_missing => 0,
        derived => 1, # from chkconfig config
}, "current NetworkManager service for ceph021");

# unconfigured units should return all units, not only relevant ones
my $ucurrent = $svc->gather_current_units($configured, $UNCONFIGURED_DISABLED);
is_deeply(scalar keys %$ucurrent, 384, "Got 384 current units (incl non-relevant for unconfigured)");

=pod

=head2 process

Test process

=cut

$cmp->{ERROR} = 0;

my ($states, $acts) = $svc->process($configured, $current, $UNCONFIGURED_IGNORE);

is($cmp->{ERROR}, 3, "3 errors logged: 1 due to 2 configured unit, one is alias of other; the 2nd/3rd due to missing_disabled");

# rbdmap is SYSV, unseen in chkconfig --list and startstop
ok($configured->{'rbdmap.service'}->{startstop}, "rbdmap has startstop");
is($configured->{'rbdmap.service'}->{state}, $STATE_ENABLED, "rbdmap should be enabled");
is($current->{'rbdmap.service'}->{state}, $STATE_DISABLED, "rbdmap is disabled)");

# cups state ok, no startstop
ok(! $configured->{'cups.service'}->{startstop}, "cups has no startstop");

# netconsole should be enabled and started
is($configured->{'netconsole.service'}->{state}, $STATE_ENABLED, "netconsole should be enabled");
ok($configured->{'netconsole.service'}->{startstop}, "netconsole has startstop");
is($current->{'netconsole.service'}->{state}, $STATE_DISABLED, "netconsole is enabled");
ok(! $svc->{unit}->is_active('netconsole.service'), "netconsole is not active");

# NetworkManager is disabled and not active. shouldn't do anything
is($configured->{'NetworkManager.service'}->{state}, $STATE_DISABLED, "NetworkManager should be disabled");
ok($configured->{'NetworkManager.service'}->{startstop}, "NetworkManager has startstop");
is($current->{'NetworkManager.service'}->{state}, $STATE_DISABLED, "NetworkManager is disabled");
ok(! $svc->{unit}->is_active('NetworkManager.service'), "NetworkManager is not active");

# processed in alphabetical order
is_deeply($states, {
    $STATE_ENABLED => ['netconsole.service', 'rbdmap.service',],
    $STATE_DISABLED => ['cups.service', 'missing_disabled.service'],
    $STATE_MASKED => [],
    'unmask' => ['cups.service'],
}, "State changes to be made");
is_deeply($acts, {
    0 => ['missing_disabled.service'],
    1 => ['netconsole.service', 'network.service', 'rbdmap.service'],
}, "Activations to be made");


# unconfigured units handling
my ($ustates, $uacts);

# if bool, units and i(gnored) units are equal
# else, check if the unconfigured_units are in the arrayref
sub check_uu
{
    my ($same, $units, $iunits, $msg, @unconfigured_units) = @_;
    if ($same) {
        is_deeply($units, $iunits, "No modified $msg compared to $UNCONFIGURED_IGNORE");
    } else {
        foreach my $uu (@unconfigured_units) {
            ok((grep {$_ eq $uu} @$units), "Found unconfigured unit $uu in $msg");
        }
    }
}

foreach my $unconf (@$unconfs) {
    next if $unconf eq $UNCONFIGURED_IGNORE;
    # use unconfigred current value (ie all units, not only relevant ones)
    my ($ustates, $uacts) = $svc->process($configured, $ucurrent, $unconf);
    diag "ustates uacts $unconf", explain $ustates, explain $uacts;
    # check for unconfigured enabled/disabled/running/non-running units
    # check that all others are not modified
    my $same_start = $unconf ne $UNCONFIGURED_ON;
    check_uu($same_start, $uacts->{1}, $acts->{1}, "start actions for $unconf",
             'syslog.service', 'syslog.target');

    my $same_stop = $unconf ne $UNCONFIGURED_OFF;
    check_uu($same_stop, $uacts->{0}, $acts->{0}, "stop actions for $unconf",
             '-.mount', 'timers.target',);

    my $same_enabled = $same_start && $unconf ne $UNCONFIGURED_ENABLED;
    check_uu($same_enabled, $ustates->{$STATE_ENABLED}, $states->{$STATE_ENABLED}, "enabled states for $unconf",
             'syslog.service', 'syslog.target', '-.mount');

    my $same_disabled = $same_stop && $unconf ne $UNCONFIGURED_DISABLED;
    check_uu($same_disabled, $ustates->{$STATE_DISABLED}, $states->{$STATE_DISABLED}, "disabled states for $unconf",
             'syslog.service', 'syslog.target', '-.mount', 'multi-user.target');
}


=pod

=head2 change

Test change

=cut

$cmp->{ERROR} = 0;
command_history_reset();
set_output("systemctl_is_active_multi_user_target");

$svc->change($states, $acts);

is($cmp->{ERROR}, 0, "No error logged while applying the changes");

ok(command_history_ok([
    # 1st states, unmask first
    "$SYSTEMCTL unmask -- cups.service",
    "$SYSTEMCTL disable -- cups.service missing_disabled.service",
    "$SYSTEMCTL enable -- netconsole.service rbdmap.service",
    # 2 activity
    "$SYSTEMCTL stop -- missing_disabled.service",
    "$SYSTEMCTL start -- netconsole.service network.service rbdmap.service",
]), "expected commands for change");

=pod

=head2 change during shutdown

Test change during shutdown

=cut

$cmp->{ERROR} = 0;
command_history_reset();
set_output("systemctl_is_active_multi_user_target_shutdown");

$svc->change($states, $acts);

is($cmp->{ERROR}, 0, "No error logged while applying the changes during shutdown");

ok(command_history_ok([
    # 1st states, unmask first
    "$SYSTEMCTL unmask -- cups.service",
    "$SYSTEMCTL disable -- cups.service missing_disabled.service",
    "$SYSTEMCTL enable -- netconsole.service rbdmap.service",
    # 2 activity
], [
    "systemctl stop",
    "systemctl start",
]), "no stop/start commands during shutdown");

=pod

=head2 configure

Test configure

=cut

$cmp->{ERROR} = 0;
command_history_reset();
set_output("systemctl_is_active_multi_user_target");

$svc->configure($cfg);

is($cmp->{ERROR}, 4, "4 errors logged while configuring (1 due to configured alias; 3 due to missing_disabled (make_cache_alias in get_current;get_aliases/fill_cache in process;is_ufstate/get_unit_show in process))");

ok(command_history_ok([
    # 1st states
    "$SYSTEMCTL unmask -- cups.service",
    "$SYSTEMCTL disable -- cups.service missing_disabled.service",
    "$SYSTEMCTL enable -- netconsole.service rbdmap.service",
    # 2 activity
    "$SYSTEMCTL stop -- missing_disabled.service",
    "$SYSTEMCTL start -- netconsole.service network.service rbdmap.service",
]), "expected commands for change");


done_testing();
