use strict;
use warnings;
use Test::More;
use Test::Quattor qw(service_services service_ceph021);

use helper;
use NCM::Component::systemd;
use NCM::Component::Systemd::Service qw($UNCONFIGURED_IGNORE); 

use NCM::Component::Systemd::Service::Unit qw(:types :states);

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

=head2 set_unconfigured_default

Test set_unconfigured_default

=cut

# Only tests the systemd setting.
is($svc->set_unconfigured_default($cfg), $UNCONFIGURED_IGNORE, "Set unconfigured to ignore");

=pod

=head2 gather_configured_services

Test gather_configured_services

=cut

is_deeply($svc->gather_configured_services($cfg), {
    test_on => {
        name => "test_on",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['rescue', 'multi-user'],
        type => $TYPE_SYSV,
    },
    test_add => {
        name => "test_add",
        startstop => 1,
        state => $STATE_DISABLED,
        targets => ['multi-user'],
        type => $TYPE_SYSV,
    },
    othername => {
        name => "othername",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['multi-user'],
        type => $TYPE_SYSV,
    },
    test2_on => {
        name => 'test2_on',
        state => $STATE_ENABLED, 
        targets => ["rescue", "multi-user"], 
        startstop => 1,
        type => $TYPE_SERVICE,
    },
    test2_add => {
        name => "test2_add",
        state => $STATE_DISABLED, 
        targets => ["multi-user"], 
        startstop => 1,
        type => $TYPE_TARGET,
    },
    othername2 => {
        name => "othername2",
        state => $STATE_ENABLED, 
        targets => ["multi-user"],
        startstop => 1,
        type => $TYPE_SERVICE,
    },
    test_off => { # from ncm-systemd
        name => "test_off",
        state => $STATE_MASKED,
        targets => ["rescue"],
        startstop => 1,
        type => $TYPE_SERVICE,
    },
    test_del => { # from ncm-systemd
        name => "test_del",
        state => $STATE_ENABLED, 
        targets => ["rescue"], 
        startstop => 0,
        type => $TYPE_SERVICE,
    }, 
}, "gathered configured services is a union of ncm-systemd and ncm-chkconfig services");

=pod

=head2 gather_current_services

Test gather_current_services

=cut

# this is from ceph021
set_output("chkconfig_list_el7");
use cmddata::service_systemctl_list_show_gen_full_el7_ceph021_load;
$cfg = get_config_for_profile('service_ceph021');

my $configured = $svc->gather_configured_services($cfg);
is_deeply($configured, {
    network => { # sysv, on
        name => "network",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['multi-user', 'graphical'],
        type => $TYPE_SERVICE,
    },
    netconsole => { # sysv, off
        name => "netconsole",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['multi-user'],
        type => $TYPE_SERVICE,
    },
    cups => { # systemd
        name => "cups",
        startstop => 0,
        state => $STATE_DISABLED,
        targets => ['graphical'],
        type => $TYPE_SERVICE,
    },
    rbdmap => { # sysv, not in chkconfig
        name => "rbdmap",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['multi-user'],
        type => $TYPE_SERVICE,
    },
}, "configured services for ceph021");

my $current = $svc->gather_current_services(keys %$configured);     

# cdp-listend, ceph, cups, ncm-cdispd, netconsole, network
# only one of them is from the systemd units (cups)
# the others are from chkconfig --list
is_deeply(scalar keys %$current, 6, "Got 6 current services");

is_deeply($current->{network}, { # sysv
        name => "network",
        startstop => 1,
        state => $STATE_ENABLED,
        targets => ['multi-user', 'graphical'],
        type => $TYPE_SERVICE,
}, "current network service for ceph021");

is_deeply($current->{netconsole}, { # sysv
        name => "netconsole",
        startstop => 1,
        state => $STATE_DISABLED,
        targets => [],
        type => $TYPE_SERVICE,
}, "current netconsole service for ceph021");

is_deeply($current->{cups}, { # systemd
        name => "cups",
        startstop => 1,
        state => $STATE_DISABLED,
        targets => [],
        type => $TYPE_SERVICE,
}, "current cups service for ceph021");

done_testing();
