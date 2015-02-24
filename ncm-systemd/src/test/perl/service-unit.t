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

use NCM::Component::Systemd::Service::Unit qw(:targets $DEFAULT_TARGET
    :types $DEFAULT_STARTSTOP
    :states $DEFAULT_STATE);
is_deeply([$TARGET_DEFAULT, $TARGET_RESCUE, $TARGET_MULTIUSER, $TARGET_GRAPHICAL,
           $TARGET_POWEROFF, $TARGET_REBOOT, $TYPE_AUTOMOUNT, $TYPE_SLICE,
           $TYPE_SCOPE, $TYPE_SNAPSHOT],
          [qw(default rescue multi-user graphical poweroff reboot automount slice scope snapshot)],
          "exported TARGET names");
is($DEFAULT_TARGET, $TARGET_MULTIUSER, "multiuser is default target");

is_deeply([$TYPE_SERVICE, $TYPE_TARGET, $TYPE_MOUNT, 
           $TYPE_SOCKET, $TYPE_TIMER, $TYPE_PATH, 
           $TYPE_SWAP, 
          ], [qw(service target mount socket timer path swap)],
          "exported TYPES names");
is($TYPE_SYSV, $TYPE_SERVICE, "pure SYSV services are mapped to service type");
is($TYPE_DEFAULT, $TYPE_SERVICE, "default type is service type");

is_deeply([$STATE_ENABLED, $STATE_DISABLED, $STATE_MASKED],
          [qw(enabled disabled masked)],
          "exported states");
is($DEFAULT_STATE, $STATE_ENABLED, "enabled is default state");

is($DEFAULT_STARTSTOP, 1, "DEFAULT startstop is $DEFAULT_STARTSTOP");

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
    state => $STATE_ENABLED,
    type => "service",
    fullname => "test_del.service",
    startstop => 0,
    targets => ["rescue"],
};

is($unit->service_text($svc),
   "service test_del (state enabled startstop 0 type service fullname test_del.service targets rescue)",
   "Generate string of service details");

=pod

=head2 init_cache

Test the init method

=cut

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

head2 get_type_cachename

Test get_type_cachename

=cut

is_deeply([$unit->get_type_cachename("simple.$TYPE_SERVICE", $TYPE_SERVICE)],
          [$TYPE_SERVICE, 'simple'],
          "Get type and cachename for simple.service");

is_deeply([$unit->get_type_cachename("simple.$TYPE_SERVICE")],
          [$TYPE_SERVICE, 'simple'],
          "Get type and cachename for simple.service from known suffix");

is_deeply([$unit->get_type_cachename("simple.$TYPE_TARGET")],
          [$TYPE_TARGET, 'simple'],
          "Get type and cachename for simple.target from known suffix");

is_deeply([$unit->get_type_cachename("arbitrary.suffix")],
          [$TYPE_SERVICE, 'arbitrary.suffix'],
          "Get type and cachename for arbitrary.suffix gets default type TYPE_SERVICE");

is_deeply([$unit->get_type_cachename("arbitrary.suffix", "arbitrarytype")],
          ["arbitrarytype", 'arbitrary.suffix'],
          "Get type and cachename for arbitrary.suffix and arbitrarytype");

=pod

=head2 make_cache_alias with units

Test make_cache_alias with list of units.

=cut

# reset the cache
$unit->init_cache();
$cmp->{ERROR} = 0;

# messagebus.servcice is an alias of dbus.service
my ($service_cache, $service_alias) = $unit->make_cache_alias($TYPE_SERVICE, "messagebus.service");
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

=head2 make_cache_alias

Generate the cache and alias for services and targets.

=cut

# reset the cache
$unit->init_cache();

use cmddata::service_systemctl_list_show_gen_full_el7_ceph021_load;

# reset errors, $cmp is logger of $unit
$cmp->{ERROR} = 0;

($service_cache, $service_alias) = $unit->make_cache_alias($TYPE_SERVICE);

is($cmp->{ERROR}, 0, 'No errors while processing cache and alias for $TYPE_SERVICE');
is(scalar keys %$service_cache, 146,
    'Found 146 non-alias services via make_cache_alias $TYPE_SERVICE');
is(scalar keys %$service_alias, 145,
    'Found 145 service aliases via make_cache_alias $TYPE_SERVICE');

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
is(scalar keys %$target_cache, 46,
    'Found 46 non-alias targets via make_cache_alias $TYPE_TARGET');
is(scalar keys %$target_alias, 55,
    'Found 55 target aliases via make_cache_alias $TYPE_TARGET');

=pod

=head2 get_aliases

Test get_aliases

=cut

my $aliases = $unit->get_aliases([qw(dbus.service messagebus network.service)]);
is_deeply($aliases, {
    messagebus => "dbus",
}, "Found aliases");

=pod

=head2 current_services

Get services via the make_cache_alias

=cut
$cmp->{ERROR} = 0;
my $name;
my $cus = $unit->current_services();

is($cmp->{ERROR}, 0, 'No errors while processing current_services');

is(scalar keys %$cus, 138,
   'Found 138 non-alias services via current_services');

$name = 'nrpe';
$svc = $cus->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state}, $STATE_ENABLED, "Service $name state enabled");
is($svc->{type}, $TYPE_SERVICE, "Service $name type $TYPE_SERVICE");
is($svc->{fullname}, "nrpe.$TYPE_SERVICE", "Fullname service $name type sysv is $name.$TYPE_SERVICE");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user"], "Service $name targets");

# on, but failed to start
$name = 'rc-local';
$svc = $cus->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state}, 'static', "Service $name state static");
is($svc->{type}, $TYPE_SERVICE, "Service $name type $TYPE_SERVICE");
is($svc->{fullname}, "$name.$TYPE_SERVICE", "Fullname service $name type service is $name.service");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user"], "Service $name targets");

# sysv service, no UnitFileState (no [Install]), derived state
$name = 'network';
$svc = $cus->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state}, $STATE_ENABLED, "Service $name state enabled");
is($svc->{derived}, 1, "Service $name state enabled is derived");
is($svc->{type}, $TYPE_SERVICE, "Service $name type $TYPE_SERVICE");
is($svc->{fullname}, "$name.$TYPE_SERVICE", "Fullname service $name type service is $name.service");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user", "graphical"], "Service $name targets");


=pod

=head2 get_wantedby

Test get_wantedby

=cut

is_deeply($unit->get_wantedby('xinetd'), {
    'xinetd.service' => 1,
    'multi-user.target' => 1,
    'graphical.target' => 1,
}, "xinetd wantedby");

is_deeply($unit->get_wantedby('xinetd', ignoreself => 1), {
    'multi-user.target' => 1,
    'graphical.target' => 1,
}, "xinetd wantedby with unit itself removed");

=pod

=head2 is_wantedby

Test is_wantedby

=cut

ok($unit->is_wantedby("sshd", "multi-user"),
    "sshd.service wanted by multi-user.target (default unit types))");
ok($unit->is_wantedby("sshd.service", "multi-user.target"),
    "sshd.service wanted by multi-user.target");
ok($unit->is_wantedby("multi-user.target", "graphical.target"),
    "multi-user.target wanted by graphical.target");

# reset errors, $cmp is logger of $unit
$cmp->{ERROR} = 0;
ok(! $unit->is_wantedby("sshd.service", "not.a.target"),
    "not.a.target not wanted by graphical.target");
is($cmp->{ERROR}, 0, "No errors for existing service but unknown target");

set_output("systemctl_list_dependencies_not_a_service_reverse");
ok(! $unit->is_wantedby("not.a.service", "not.a.target"),
    "not.a.target not wanted by not.a.service");
# TODO: 2 errors are logged: one from systemctl and one from is_wantedby
#   need to rethink the error logging
is($cmp->{ERROR}, 2, "Error logged for unknown service");

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
my $cos = $unit->configured_services($tree);
is_deeply($cos, {
    test2_on => {
        name => 'test2_on',
        state => $STATE_ENABLED,
        targets => ["rescue", "multi-user"],
        startstop => 1,
        type => $TYPE_SERVICE,
        fullname => "test2_on.$TYPE_SERVICE",
    },
    test2_add => {
        name => "test2_add",
        state => $STATE_DISABLED,
        targets => ["multi-user"],
        startstop => 1,
        type => $TYPE_TARGET,
        fullname => "test2_add.$TYPE_TARGET",
    },
    othername2 => {
        name => "othername2",
        state => $STATE_ENABLED,
        targets => ["multi-user"],
        startstop => 1,
        type => $TYPE_SERVICE,
        fullname => "othername2.$TYPE_SERVICE",
    },
    test_off => {
        name => "test_off",
        state => $STATE_MASKED,
        targets => ["rescue"],
        startstop => 1,
        type => $TYPE_SERVICE,
        fullname => "test_off.$TYPE_SERVICE",
    },
    test_del => {
        name => "test_del",
        state => $STATE_ENABLED,
        targets => ["rescue"],
        startstop => 0,
        type => $TYPE_SERVICE,
        fullname => "test_del.$TYPE_SERVICE",
    },
}, "configured_services set correct name and type");

=pod

=head2 fill_cache

Test fill_cache

=cut

    $TYPE_SOCKET, $TYPE_TIMER, $TYPE_PATH,
    $TYPE_SWAP, $TYPE_AUTOMOUNT, $TYPE_SLICE,
    $TYPE_SCOPE, $TYPE_SNAPSHOT,

my $updated = $unit->fill_cache(0, "network.service", "multi-user.target", "ceph.service", "network.target");
is_deeply($updated, {
    $TYPE_SERVICE => [],
    $TYPE_TARGET => [],
    $TYPE_MOUNT => [],
    $TYPE_SOCKET => [],
    $TYPE_TIMER => [],
    $TYPE_PATH => [],
    $TYPE_SWAP => [],
    $TYPE_AUTOMOUNT => [],
    $TYPE_SLICE => [],
    $TYPE_SCOPE => [],
    $TYPE_SNAPSHOT => [],
}, "update_cache force=0 updated no services (they are all in cache already)");

$updated = $unit->fill_cache(1, "network.service", "multi-user.target", "ceph.service", "network.target");
is_deeply($updated, {
    $TYPE_SERVICE => ['network.service', 'ceph.service'],
    $TYPE_TARGET => ['multi-user.target', 'network.target'],
    $TYPE_MOUNT => [],
    $TYPE_SOCKET => [],
    $TYPE_TIMER => [],
    $TYPE_PATH => [],
    $TYPE_SWAP => [],
    $TYPE_AUTOMOUNT => [],
    $TYPE_SLICE => [],
    $TYPE_SCOPE => [],
    $TYPE_SNAPSHOT => [],
}, "update_cache force=1 updated the correct services with their types");

=pod

=head2 get_unit_show

Test get_unit_show

=cut

is($unit->get_unit_show('network.service', 'UnitFileState'),
   '', 'get_unit_show network.service empty UnitFileState');
is($unit->get_unit_show('network.service', 'ActiveState'),
   'failed', 'get_unit_show network.service ActiveState');
is_deeply($unit->get_unit_show('network.service', 'WantedBy'),
   ['multi-user.target', 'graphical.target'], 'get_unit_show network.service WantedBy');

=pod

=head2 is_active

Test is_active

=cut

# TODO test the looping / mapping?

$cmp->{ERROR} = 0;

# ceph021 output
# active
ok($unit->is_active('ncm-cdispd', type => 'service'),
   'Active ncm-cdispd SYSV service is active');
# inactive
ok(! $unit->is_active('cups', type => 'service'),
   'Inactive cups service is not active');
# failed
ok(! $unit->is_active('rc-local', type => 'service'),
   'Failed rc-local service is not active');

# Force a reloading service.
# This is from helper.pm
use cmddata;
my $cmdshort = 'gen_full_el7_ceph021_systemctl_show_xinetd_service_units';
my $cmdline= $cmddata::cmds{$cmdshort}{cmd};
my $out=$cmddata::cmds{$cmdshort}{out};
$out =~ s/^ActiveState\s*=.*$/ActiveState=reloading/m;
set_desired_output($cmdline, $out);

# Force reloading the cache; retrials will always give same answer
# and then static mapping will kick in.
ok($unit->is_active('xinetd', type => 'service', force => 1),
   'Reloading xinetd service is mapped to active');

$out =~ s/^ActiveState\s*=.*$/ActiveState=activating/m;
set_desired_output($cmdline, $out);
ok($unit->is_active('xinetd', type => 'service', force => 1),
   'Activating xinetd service is mapped to active');

$out =~ s/^ActiveState\s*=.*$/ActiveState=deactivating/m;
set_desired_output($cmdline, $out);
ok(! $unit->is_active('xinetd', type => 'service', force => 1),
   'Deactivating xinetd service is mapped to inactive');

is($cmp->{ERROR}, 0, "No errors logged for known ActiveStates");

$out =~ s/^ActiveState\s*=.*$/ActiveState=unkown/m;
set_desired_output($cmdline, $out);
ok(! defined($unit->is_active('xinetd', type => 'service', force => 1)),
   'Unknown ActiveState returns undef');
is($cmp->{ERROR}, 1, "Error logged for unknown ActiveState");

# restore
$out =~ s/^ActiveState\s*=.*$/ActiveState=active/m;
set_desired_output($cmdline, $out);

=pod

=head2 get_ufstate

Test get_ufstate

=cut

my ($ufstate, $derived) = $unit->get_ufstate('xinetd', type => 'service');
is($ufstate, $STATE_ENABLED, 'get_ufstate xinetd UnitFileState is $STATE_ENABLED');
is($derived, $STATE_ENABLED, 'get_ufstate xinetd derived state is $STATE_ENABLED');

($ufstate, $derived) = $unit->get_ufstate('network.service');
is($ufstate, '', 'get_ufstate network UnitFileState is empty string'); 
is($derived, $STATE_ENABLED, 'get_ufstate network derived state is $STATE_ENABLED'); 

=pod

=head2 is_ufstate

Test is_ufstate

=cut

my $states = {
    enabled => 'enabled',
    'enabled-runtime' => 0,
    linked => 1,
    'linked-runtime' => 0,
    masked => 'masked',
    'masked-runtime' => 0,
    static => 1,
    disabled => 'disabled',
    invalid => 0,
};

my $supported = [$STATE_ENABLED, $STATE_DISABLED, $STATE_MASKED];

while (my ($ufstate, $val) = each %$states) {
    my @ok; # 1
    my @notok; # 0
    if ($val eq 1) {
        # whatever the state, it will return 1
        push(@ok, @$supported);
    } elsif ($val eq 0) {
        # whatever the state, it will return 0
        push(@notok, @$supported);
    } else {
        # return 1 for state
        push(@ok, grep {$_ eq $val} @$supported);
        push(@notok, grep {$_ ne $val} @$supported);
    }

    $out =~ s/^UnitFileState\s*=.*$/UnitFileState=$ufstate/m;
    set_desired_output($cmdline, $out);

    foreach my $state (@ok) {
        ok($unit->is_ufstate('xinetd', $state,  type => 'service', force => 1),
           "is_ufstate for ufstate $ufstate and state $state");
    }

    foreach my $state (@notok) {
        ok(! $unit->is_ufstate('xinetd', $state,  type => 'service', force => 1),
           "is_ufstate not for ufstate $ufstate and state $state");
    }
}

# Reset value to original
$out =~ s/^UnitFileState\s*=.*$/UnitFileState=enabled/m;
set_desired_output($cmdline, $out);

done_testing();
