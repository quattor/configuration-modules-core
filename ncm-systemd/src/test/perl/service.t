use strict;
use warnings;
use Test::More;
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

my $svc = NCM::Component::Systemd::Service->new(log => $cmp);
isa_ok($svc, "NCM::Component::Systemd::Service",
       "Created a NCM::Component::Systemd::Service instance");
isa_ok($svc->{unit}, "NCM::Component::Systemd::Service::Unit",
       "Has a NCM::Component::Systemd::Service::Unit instance");
isa_ok($svc->{chkconfig}, "NCM::Component::Systemd::Service::Chkconfig",
       "Has a NCM::Component::Systemd::Service::Chkconfig instance");

=pod

=head2 exported constants

=cut

is_deeply([$UNCONFIGURED_DISABLED, $UNCONFIGURED_ENABLED,
           $UNCONFIGURED_IGNORE, $UNCONFIGURED_MASKED,
          ],
          [qw(disabled enabled ignore masked)],
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

is_deeply($svc->gather_configured_units($cfg), {
    'test_on.service' => {
        name => "test_on.service",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['rescue.target', 'multi-user.target'],
        type => $TYPE_SYSV,
        shortname => "test_on",
    },
    'test_add.service' => {
        name => "test_add.service",
        startstop => 1,
        state => $STATE_DISABLED,
        targets => ['multi-user.target'],
        type => $TYPE_SYSV,
        shortname => "test_add",
    },
    'othername.service' => {
        name => "othername.service",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['multi-user.target'],
        type => $TYPE_SYSV,
        shortname => "othername",
    },
    'test2_on.service' => {
        name => "test2_on.service",
        state => $STATE_ENABLED,
        targets => ["rescue.target", "multi-user.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "test2_on",
    },
    'test2_add.target' => {
        name => "test2_add.target",
        state => $STATE_DISABLED,
        targets => ["multi-user.target"],
        startstop => 1,
        type => $TYPE_TARGET,
        shortname => "test2_add",
    },
    'othername2.service' => {
        name => "othername2.service",
        state => $STATE_ENABLED,
        targets => ["multi-user.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "othername2",
    },
    'test_off.service' => { # from ncm-systemd
        name => "test_off.service",
        state => $STATE_MASKED,
        targets => ["rescue.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "test_off",
    },
    'test_del.service' => { # from ncm-systemd
        name => "test_del.service",
        state => $STATE_ENABLED,
        targets => ["rescue.target"],
        startstop => 0,
        type => $TYPE_SERVICE,
        shortname => "test_del",
    },
}, "gathered configured units is a union of ncm-systemd and ncm-chkconfig units");

=pod

=head2 gather_current_units

Test gather_current_units

=cut

# this is from ceph021
set_output("chkconfig_list_el7");
use cmddata::service_systemctl_list_show_gen_full_el7_ceph021_load;
$cfg = get_config_for_profile('service_ceph021');

my $configured = $svc->gather_configured_units($cfg);
is_deeply($configured->{'network.service'}, { # sysv, on
    name => "network.service",
    startstop => 1,
    state => $STATE_ENABLED,
    targets => ['multi-user.target', 'graphical.target'],
    type => $TYPE_SERVICE,
    shortname => "network",
}, "configured network service for ceph021");

is_deeply($configured->{'netconsole.service'}, { # sysv, off
    name => "netconsole.service",
    startstop => 1,
    state => $STATE_ENABLED,
    targets => ['multi-user.target'],
    type => $TYPE_SERVICE,
    shortname => "netconsole",
}, "configured netconsole service for ceph021");

is_deeply($configured->{'cups.service'}, { # systemd
    name => "cups.service",
    startstop => 0,
    state => $STATE_DISABLED,
    targets => ['graphical.target'],
    type => $TYPE_SERVICE,
    shortname => "cups",
}, "configured cups service for ceph021");

is_deeply($configured->{'rbdmap.service'}, { # sysv, not in chkconfig
    name => "rbdmap.service",
    startstop => 1,
    state => $STATE_ENABLED,
    targets => ['multi-user.target'],
    type => $TYPE_SERVICE,
    shortname => "rbdmap",
}, "configured rbdmap service for ceph021");

my $current = $svc->gather_current_units($configured);

# cdp-listend, ceph, cups, ncm-cdispd, netconsole, network
# only one of them is from the systemd units (cups)
# the others are from chkconfig --list
is_deeply(scalar keys %$current, 10, "Got 10 current units");

is_deeply($current->{'network.service'}, { # sysv
        name => "network.service",
        startstop => 1,
        state => $STATE_ENABLED,
        derived => 1,
        targets => ['multi-user.target', 'graphical.target'],
        type => $TYPE_SERVICE,
        shortname => "network",
}, "current network service for ceph021");

is_deeply($current->{'netconsole.service'}, { # sysv
        name => "netconsole.service",
        startstop => 1,
        state => $STATE_DISABLED,
        derived => 1,
        targets => [],
        type => $TYPE_SERVICE,
        shortname => "netconsole",
}, "current netconsole service for ceph021");

is_deeply($current->{'cups.service'}, { # systemd
        name => "cups.service",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => [],
        type => $TYPE_SERVICE,
        shortname => "cups",
}, "current cups service for ceph021");

=pod

=head2 process

Test process

=cut

$cmp->{ERROR} = 0;

my ($states, $acts) = $svc->process($configured, $current);

is($cmp->{ERROR}, 1, "1 error raise due to 2 configured unit, one is alias of other.");

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
ok(! $svc->{unit}->is_active('netconsole.service'), "notconsole is not active");


# processed in alphabetical order
is_deeply($states, {
    $STATE_ENABLED => ['netconsole.service', 'rbdmap.service',],
    $STATE_DISABLED => ['cups.service'],
    $STATE_MASKED => [],
}, "State changes to be made");
is_deeply($acts, {
    0 => [],
    1 => ['netconsole.service', 'network.service', 'rbdmap.service'],
}, "Activations to be made");

=pod

=head2 change

Test change

=cut

$cmp->{ERROR} = 0;
command_history_reset();

$svc->change($states, $acts);

is($cmp->{ERROR}, 0, "No error logger while applying the changes");

ok(command_history_ok([
    # 1st states, alpahbetically ordered
    "$SYSTEMCTL disable -- cups.service",
    "$SYSTEMCTL enable -- netconsole.service rbdmap.service",
    # 2 activity
    "$SYSTEMCTL start -- netconsole.service network.service rbdmap.service",
]), "expected commands for change");

=pod

=head2 configure

Test configure

=cut

$cmp->{ERROR} = 0;
command_history_reset();

$svc->configure($cfg);

is($cmp->{ERROR}, 1, "1 error logged while configuring (due to configured alias)");

ok(command_history_ok([
    # 1st states, alpahbetically ordered
    "$SYSTEMCTL disable -- cups.service",
    "$SYSTEMCTL enable -- netconsole.service rbdmap.service",
    # 2 activity
    "$SYSTEMCTL start -- netconsole.service network.service rbdmap.service",
]), "expected commands for change");


done_testing();
