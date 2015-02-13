use strict;
use warnings;
use Test::More;
use Test::Quattor qw(service_services);

use helper;
use NCM::Component::systemd;
use NCM::Component::Systemd::Service;

use NCM::Component::Systemd::Service::Unit qw(:types);

$CAF::Object::NoAction = 1;

# need a logger instance (could also use CAF::Object instance)
my $cmp = NCM::Component::systemd->new('systemd');

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

=head2 gather_services

Test gather_services

=cut

my $cfg = get_config_for_profile('service_services');



is_deeply($svc->gather_services($cfg), {
    test_on => {
        name => "test_on",
        startstop => 1,
        state => "on",
        targets => ['rescue', 'multi-user'],
        type => $TYPE_SYSV,
    },
    test_add => {
        name => "test_add",
        startstop => 1,
        state => "add",
        targets => ['multi-user'],
        type => $TYPE_SYSV,
    },
    othername => {
        name => "othername",
        startstop => 1,
        state => "on",
        targets => ['multi-user'],
        type => $TYPE_SYSV,
    },
    test2_on => {
        name => 'test2_on',
        state => "on", 
        targets => ["rescue", "multi-user"], 
        startstop => 1,
        type => $TYPE_SERVICE,
    },
    test2_add => {
        name => "test2_add",
        state => "add", 
        targets => ["multi-user"], 
        startstop => 1,
        type => $TYPE_TARGET,
    },
    othername2 => {
        name => "othername2",
        state => "on", 
        targets => ["multi-user"],
        startstop => 1,
        type => $TYPE_SERVICE,
    },
    test_off => { # from ncm-systemd
        name => "test_off",
        state => "del",
        targets => ["rescue"],
        startstop => 1,
        type => $TYPE_SERVICE,
    },
    test_del => { # from ncm-systemd
        name => "test_del",
        state => "on", 
        targets => ["rescue"], 
        startstop => 0,
        type => $TYPE_SERVICE,
    }, 
},"gathered services is a union of ncm-systemd and ncm-chkconfig services");
