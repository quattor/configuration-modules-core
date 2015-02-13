use strict;
use warnings;
use Test::More;
use Test::Quattor qw(service-unit_services);

use helper;
use NCM::Component::systemd;

$CAF::Object::NoAction = 1;

# need a logger instance (could also use CAF::Object instance)
my $cmp = NCM::Component::systemd->new('systemd');

=pod

=head1 DESCRIPTION

Test C<NCM::Component::Systemd::Service::Unit> module for systemd.

=head2 EXPORTS

Test exports

=cut

use NCM::Component::Systemd::Service::Unit qw(:targets $DEFAULT_TARGET :types $DEFAULT_STARTSTOP $DEFAULT_STATE);
is_deeply([$TARGET_DEFAULT, $TARGET_RESCUE, $TARGET_MULTIUSER, $TARGET_GRAPHICAL,
           $TARGET_POWEROFF, $TARGET_REBOOT],
          [qw(default rescue multi-user graphical poweroff reboot)],
          "exported TARGET names");
is($DEFAULT_TARGET, $TARGET_MULTIUSER, "multiuser is default target");

is_deeply([$TYPE_SYSV, $TYPE_SERVICE, $TYPE_TARGET],
          [qw(sysv service target)],
           "exported TYPES names");

is($DEFAULT_STARTSTOP, 1, "DEFAULT startstop is $DEFAULT_STARTSTOP"); 
is($DEFAULT_STATE, "on", "DEFAULT state is $DEFAULT_STATE");

=head2 new

Test creation of Unit instance

=cut

my $unit = NCM::Component::Systemd::Service::Unit->new(log => $cmp);
isa_ok($unit, "NCM::Component::Systemd::Service::Unit",
        "NCM::Component::Systemd::Service::Unit instance created");

=pod

=head2 service_text

Test the generating text message from service details

=cut

my $svc = {
    name => "test_del",
    state => "on",
    type => "service",
    startstop => 0,
    targets => ["rescue"],
};

is($unit->service_text($svc), 
   "service test_del (state on startstop 0 type service targets rescue)", 
   "Generate string of service details");

=pod

=head2 init_cache

Test the init method

=pod

my ($u_c, $u_a, $d_c) = $unit->init_cache();
is_deeply($u_c, {
    service => {},
    target => {},    
}, "unit_cache initialised");

is_deeply($u_a, {
    service => {},
    target => {},    
}, "unit_alias initialised");

is_deeply($d_c, {
    deps => {},
    rev => {},    
}, "dependency_cache initialised");

=pod

=head2 make_cache_alias

Generate the cache and alias for services and targets.

=cut

# reset the cache
$unit->init_cache();

use cmddata::service_systemctl_list_show_gen_full_el7_ceph021_load;

# reset errors, $cmp is logger of $unit
$cmp->{ERROR} = 0;

my ($service_cache, $service_alias) = $unit->make_cache_alias($TYPE_SERVICE);

is($cmp->{ERROR}, 0, 'No errors while processing cache and alias for $TYPE_SERVICE');
is(scalar keys %$service_cache, 145,
    'Found 145 non-alias services via make_cache_alias $TYPE_SERVICE');
is(scalar keys %$service_alias, 144, 
    'Found 144 service aliases via make_cache_alias $TYPE_SERVICE');

# Tests for
# sshd@ base instance service, different from sshd service
ok($service_cache->{'sshd@'}->{baseinstance}, 'sshd@ base instance found');
ok($service_cache->{'sshd'}->{show}, 'sshd service found with show data');
ok(! $service_cache->{'sshd'}->{baseinstance}, 'sshd service is not a base instance');

# getty@tty1 instance vs getty@ instance unit-file
ok($service_cache->{'getty@'}->{baseinstance}, 'getty@ base instance found');
ok(! $service_cache->{'getty@'}->{instance}, 'getty@ base instance has no instance data');

ok(exists($service_cache->{'getty@tty1'}), 'getty@tty1 instance found');
ok(! $service_cache->{'getty@tty1'}->{baseinstance}, 'getty@tty1 is not a base instance');
is($service_cache->{'getty@tty1'}->{instance}, 'tty1', 'getty@tty1 instance has instance data');

# some aliases
is($service_alias->{'dbus-org.freedesktop.hostname1'}, 'systemd-hostnamed', 
    "dbus-org.freedesktop.hostname1 is alias of systemd-hostnamed");
is($service_alias->{'systemd-hostnamed'}, 'systemd-hostnamed', 
    "systemd-hostnamed is alias of itself (all services are in alias list)");
ok(! $service_cache->{'dbus-org.freedesktop.hostname1'}, 
    "Pure alias dbus-org.freedesktop.hostname1 is not in cache");

my ($target_cache, $target_alias) = $unit->make_cache_alias($TYPE_TARGET);

is($cmp->{ERROR}, 0, 'No errors while processing cache and alias for $TYPE_TARGET');
is(scalar keys %$target_cache, 45, 
    'Found 45 non-alias targets via make_cache_alias $TYPE_TARGET');
is(scalar keys %$target_alias, 54, 
    'Found 54 target aliases via make_cache_alias $TYPE_TARGET');

=pod

=head2 make_cache_alias with units

Test make_cache_alias with list of unites.

=cut

# reset the cache
$unit->init_cache();
$cmp->{ERROR} = 0;

# messagebus.servcice is an alias of dbus.service
($service_cache, $service_alias) = $unit->make_cache_alias($TYPE_SERVICE, "messagebus.service");
is($cmp->{ERROR}, 0, 'No errors while processing cache and alias for $TYPE_SERVICE and units messagebus.service');

is($service_alias->{'messagebus'}, 'dbus', 'messagebus is an alias for dbus');

is($service_alias->{'dbus'}, 'dbus', 'dbus is its own alias');
ok(! $service_cache->{messagebus}->{show}, "no show details for alias messagebus");
ok($service_cache->{dbus}->{show}, "show details fro dbus");


# basic info from list-units / list-unit-files for all units
# only show info for messagebus / dbus
ok($service_cache->{'sshd'}, 'basic cache info for sshd service');
ok(! defined $service_cache->{'sshd'}->{show}, 'no show cache info for sshd service');


=pod

=head2 current_services

Get services via the make_cache_alias

=cut
$cmp->{ERROR} = 0;
my $name;
my $cs = $unit->current_services();

is($cmp->{ERROR}, 0, 'No errors while processing current_services');

is(scalar keys %$cs, 137, 
   'Found 137 non-alias services via current_services');

$name = 'nrpe';
$svc = $cs->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state},"on", "Service $name state disabled");
is($svc->{type}, "service", "Service $name type sysv");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user"], "Service $name targets");

# on, but failed to start
$name = 'rc-local';
$svc = $cs->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state},"on", "Service $name state disabled");
is($svc->{type}, "service", "Service $name type sysv");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user"], "Service $name targets");

=pod

=head2 wanted_by

Test wanted_by

=cut

set_output("systemctl_list_dependencies_sshd_service_reverse");
set_output("systemctl_list_dependencies_multiuser_target_reverse");
ok($unit->wanted_by("sshd", "multi-user"), 
    "sshd.service wanted by multi-user.target (default unit types))");
ok($unit->wanted_by("sshd.service", "multi-user.target"), 
    "sshd.service wanted by multi-user.target");
ok($unit->wanted_by("multi-user.target", "graphical.target"), 
    "multi-user.target wanted by graphical.target");

# reset errors, $cmp is logger of $unit
$cmp->{ERROR} = 0;
ok(! $unit->wanted_by("sshd.service", "not.a.target"), 
    "not.a.target not wanted by graphical.target");
is($cmp->{ERROR}, 0, "No errors for existing service but unknown target");

set_output("systemctl_list_dependencies_not_a_service_reverse");
ok(! $unit->wanted_by("not.a.service", "not.a.target"), 
    "not.a.target not wanted by not.a.service");
is($cmp->{ERROR}, 1, "Error logged for unknown service");

=pod

=head2 default_target

Test default_target

=cut

set_output('gen_full_el7_ceph021_systemctl_show_default_target_unit-files');
is($unit->default_target(), 'multi-user', 'Found multi-user as default.target');

=pod

=head2 configured_services

Test configured services

=cut

my $cfg = get_config_for_profile('service-unit_services');
my $tree = $cfg->getElement('/software/components/systemd/service')->getTree();
is_deeply($unit->configured_services($tree), {
    test2_on => {
        name => 'test2_on',
        state => "on", 
        targets => ["rescue", "multi-user"], 
        startstop => 1,
        type => $TYPE_SERVICE,
    },
    test2_add => {
        name => "test2_add",
        state => "off", 
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
    test_off => {
        name => "test_off",
        state => "del",
        targets => ["rescue"],
        startstop => 1,
        type => $TYPE_SERVICE,
    },
    test_del => {
        name => "test_del",
        state => "on", 
        targets => ["rescue"], 
        startstop => 0,
        type => $TYPE_SERVICE,
    },
}, "configured_services set correct name and type");


done_testing();
