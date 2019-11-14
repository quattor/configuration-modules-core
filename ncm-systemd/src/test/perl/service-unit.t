use strict;
use warnings;
use Test::More;
use Test::Quattor qw(service-unit_services);
use Test::MockModule;

use helper;
use NCM::Component::systemd;
use NCM::Component::Systemd::Systemctl qw($SYSTEMCTL);

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
    :states $DEFAULT_STATE
);
is_deeply([$TARGET_DEFAULT, $TARGET_RESCUE, $TARGET_MULTIUSER, $TARGET_GRAPHICAL,
           $TARGET_POWEROFF, $TARGET_REBOOT,
          ],
          [qw(default rescue multi-user graphical poweroff reboot)],
          "exported TARGET names");
is($DEFAULT_TARGET, $TARGET_MULTIUSER, "multiuser is default target");

is_deeply([$TYPE_SERVICE, $TYPE_TARGET, $TYPE_MOUNT,
           $TYPE_SOCKET, $TYPE_TIMER, $TYPE_PATH,
           $TYPE_SWAP, $TYPE_AUTOMOUNT, $TYPE_SLICE,
           $TYPE_SCOPE, $TYPE_SNAPSHOT, $TYPE_DEVICE
          ], [qw(service target mount socket timer path swap automount slice scope snapshot device)],
          "exported TYPES names");
is($TYPE_SYSV, $TYPE_SERVICE, "pure SYSV services are mapped to service type");
is($DEFAULT_TYPE, $TYPE_SERVICE, "default type is service type");

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

ok(get_command('/usr/bin/systemctl daemon-reload'), 'daemon-reload called upon init');


=pod

=head2 is_possible_missing

Test is_possible_missing

=cut

is($unit->is_possible_missing("myunit", $STATE_MASKED), 1, "State masked is possible_missing");
is($unit->is_possible_missing("myunit", $STATE_DISABLED), 0, "State disabled is not possible_missing");
is($unit->is_possible_missing("myunit", "notastate"), 0, "Default is not possible_missing");


=pod

=head2 service_text

Test the generating text message from service details

=cut

my $svc = {
    name => "test_del.service",
    state => $STATE_ENABLED,
    type => "service",
    shortname => "test_del",
    startstop => 0,
    targets => ["rescue.target"],
    possible_missing => 0,
};

$cmp->{ERROR} = 0;
is($unit->unit_text($svc),
   "unit test_del.service (state enabled startstop 0 type service shortname test_del targets rescue.target possible_missing 0)",
   "unit_text generate string of unit details");

ok(! $cmp->{ERROR}, "unit_text no error with correct unit");

delete $svc->{name};
ok(! defined($unit->unit_text($svc)),
   "unit_text unit details with missing name attribute generates returns undef");
is($cmp->{ERROR}, 1, "unit_text error with incorrect unit");

$svc->{name} = "test_del.serviceX";
ok(! defined($unit->unit_text($svc)),
   "unit_text unit details with mismatch between name and fullname returns undef");
is($cmp->{ERROR}, 2, "unit_text error with incorrect unit");

$svc->{name} = "test_del.service";
delete $svc->{startstop};
# This generates text, but generates error
is($unit->unit_text($svc),
   "unit test_del.service (state enabled type service shortname test_del targets rescue.target possible_missing 0)",
   "unit_text generate string of unit details");
is($cmp->{ERROR}, 3, "unit_text error with incorrect unit");

# reset error counter
$cmp->{ERROR} = 0;

=pod

=head2 init_cache

Test the init method

=cut

my ($u_c, $u_a, $d_c) = $unit->init_cache();
is_deeply($u_c, {}, "unit_cache initialised");

is_deeply($u_a, {}, "unit_alias initialised");

is_deeply($d_c, {
    deps => {},
    rev => {},
}, "dependency_cache initialised");

=pod

head2 get_type_shortname

Test get_type_shortname

=cut

is_deeply([$unit->get_type_shortname("simple.$TYPE_SERVICE")],
          [$TYPE_SERVICE, 'simple'],
          "Get type and shortname for simple.service from known suffix");

is_deeply([$unit->get_type_shortname("simple.$TYPE_TARGET")],
          [$TYPE_TARGET, 'simple'],
          "Get type and shortname for simple.target from known suffix");

is_deeply([$unit->get_type_shortname("simple.$TYPE_SERVICE", $TYPE_SERVICE)],
          [$TYPE_SERVICE, 'simple'],
          "Get type and shortname for simple.service");

is_deeply([$unit->get_type_shortname("simple.$TYPE_SLICE", undef, $TYPE_SOCKET)],
          [$TYPE_SLICE, 'simple'],
          "Get type and shortname for simple.$TYPE_SLICE with defaulttype $TYPE_SOCKET");

is_deeply([$unit->get_type_shortname("simple", undef, $TYPE_SOCKET)],
          [$TYPE_SOCKET, 'simple'],
          "Get type and shortname for simple with defaulttype $TYPE_SOCKET");

is_deeply([$unit->get_type_shortname("arbitrary.suffix", "arbitrarytype")],
          ["arbitrarytype", 'arbitrary.suffix'],
          "Get type and shortname for arbitrary.suffix and arbitrarytype");

is($cmp->{ERROR}, 0, "No errors after regular get_type_shortname usage");

is_deeply([$unit->get_type_shortname("arbitrary.suffix")],
          [$DEFAULT_TYPE, 'arbitrary.suffix'],
          "Get type and shortname for arbitrary.suffix gets default type DEFAULT_TYPE");
is($cmp->{ERROR}, 1, "1 error logger after get_type_shortname usage with unsupported type");

# reset error counter
$cmp->{ERROR} = 0;

=pod

=head2 make_cache_alias with units

Test make_cache_alias with list of units.

=cut

# reset the cache
$unit->init_cache();
$cmp->{ERROR} = 0;

use cmddata::service_systemctl_list_show_gen_full_el7_ceph021_load;

# messagebus.servcice is an alias of dbus.service
my ($cache, $alias) = $unit->make_cache_alias(["messagebus.service", "missing1.mount", "missing2.slice"], ["missing2.slice"]);
is($cmp->{ERROR}, 1, '1 error while processing cache and alias (due to missing1.mount not a possible_missing unit');
ok(! $cache->{'missing1.mount'}, "missing1.mount is missing");
ok(! $cache->{'missing2.slice'}, "missing2.slice is missing");

# basic info from list-units / list-unit-files for all units
# only show info for messagebus / dbus
ok($cache->{'sshd.service'}, 'basic cache info for sshd.service');
ok(! defined $cache->{'sshd.service'}->{show}, 'no show cache info for sshd.service');

is($alias->{'messagebus.service'}, 'dbus.service', 'messagebus.service is an alias for dbus');

is($alias->{'dbus.service'}, 'dbus.service', 'dbus.service is its own alias');
ok(! $cache->{'messagebus.service'}->{show}, "no show details for alias messagebus.service");
ok($cache->{'dbus.service'}->{show}, "show details for dbus.service");

=pod

=head2 _handle_bug_wrong_escaped_unit

=cut

my $unit0 = 'systemd-fsck@dev-mapper-vg0\x2dscratch.service';
my $id0 = 'systemd-fsck@dev-mapper-vg0\x5cx2dscratch.service';
is($unit->_handle_bug_wrong_escaped_unit($id0, $unit0), $unit0, "catched buggy id 0");

#/usr/bin/systemctl --no-pager --all show -- "dev-disk-by\x2duuid-914a35f9\x2dd3c7\x2d47cb\x2db2dc\x2dff94ba1adbb6.swap" |grep Id=
#Id=dev-disk-by\x5cx2duuid-914a35f9\x5cx2dd3c7\x5cx2d47cb\x5cx2db2dc\x5cx2dff94ba1adbb6.swap
my $unit1 = 'dev-disk-by\x2duuid-914a35f9\x2dd3c7\x2d47cb\x2db2dc\x2dff94ba1adbb6.swap';
my $id1 = 'dev-disk-by\x5cx2duuid-914a35f9\x5cx2dd3c7\x5cx2d47cb\x5cx2db2dc\x5cx2dff94ba1adbb6.swap';
is($unit->_handle_bug_wrong_escaped_unit($id1, $unit1), $unit1, "catched buggy id 1");

is($unit->_handle_bug_wrong_escaped_unit("abc", "abc"), "abc", "return correct id on same value");

is($unit->_handle_bug_wrong_escaped_unit("abc", "def"), "abc", "return correct id on different value");


=pod

=head2 make_cache_alias

Generate the cache and alias for all units.

=cut

# reset the cache
$unit->init_cache();

# reset errors, $cmp is logger of $unit
$cmp->{ERROR} = 0;

($cache, $alias) = $unit->make_cache_alias();

is($cmp->{ERROR}, 0, 'No errors while processing cache and alias for all units');
is(scalar keys %$cache, 392,
    'Found 392 non-alias units via make_cache_alias');
is(scalar keys %$alias, 400,
    'Found 400 unit aliases via make_cache_alias');

# Tests for
# sshd@ base instance service, different from sshd service
ok($cache->{'sshd@.service'}->{baseinstance}, 'sshd@.service base instance found');
ok($cache->{'sshd.service'}->{show}, 'sshd.service found with show data');
ok(! $cache->{'sshd.service'}->{baseinstance}, 'sshd.service is not a base instance');

# getty@tty1 instance vs getty@ instance unit-file
ok($cache->{'getty@.service'}->{baseinstance}, 'getty@.service base instance found');
ok(! $cache->{'getty@.service'}->{instance}, 'getty@.service base instance has no instance data');

ok(exists($cache->{'getty@tty1.service'}), 'getty@tty1.service instance found');
ok(! $cache->{'getty@tty1.service'}->{baseinstance}, 'getty@tty1.service is not a base instance');
is($cache->{'getty@tty1.service'}->{instance}, 'tty1', 'getty@tty1.service instance has instance data');

# some aliases
is($alias->{'dbus-org.freedesktop.hostname1.service'}, 'systemd-hostnamed.service',
    "dbus-org.freedesktop.hostname1.service is alias of systemd-hostnamed.service");
is($alias->{'systemd-hostnamed.service'}, 'systemd-hostnamed.service',
    "systemd-hostnamed.service is alias of itself (all services are in alias list)");
ok(! $cache->{'dbus-org.freedesktop.hostname1.service'},
    "Pure alias dbus-org.freedesktop.hostname1.service is not in cache");

=pod

=head2 get_aliases

Test get_aliases

=cut

my $aliases = $unit->get_aliases([qw(dbus.service messagebus.service network.service)]);
is_deeply($aliases, {
    'messagebus.service' => "dbus.service",
}, "get_aliases Found aliases");

=pod

=head2 get_wantedby

Test get_wantedby

=cut

is_deeply($unit->get_wantedby('xinetd.service'), {
    'xinetd.service' => 1,
    'multi-user.target' => 1,
    'graphical.target' => 1,
}, "xinetd.service wantedby");

is_deeply($unit->get_wantedby('xinetd.service', ignoreself => 1), {
    'multi-user.target' => 1,
    'graphical.target' => 1,
}, "xinetd.service wantedby with unit itself removed");

=pod

=head2 is_wantedby

Test is_wantedby

=cut

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

is($unit->default_target(), 'multi-user.target', 'Found multi-user as default.target');

=pod

=head2 fill_cache

Test fill_cache

=cut

my $updated = $unit->fill_cache(["network.service", "multi-user.target", "ceph.service", "network.target"], force => 0);
is_deeply($updated, [],
          "fill_cache force=0 updated no services (they are all in cache already)");

$updated = $unit->fill_cache(["network.service", "multi-user.target", "ceph.service", "network.target"], force => 1);
is_deeply($updated,
          ["network.service", "multi-user.target", "ceph.service", "network.target"],
          "fill_cache force=1 updated the correct services with their types");

=pod

=head2 get_unit_show

Test get_unit_show

=cut

is($unit->get_unit_show('network.service', 'UnitFileState'),
   '',
   'get_unit_show network.service empty UnitFileState'
    );
is($unit->get_unit_show('network.service', 'ActiveState'),
   'failed',
   'get_unit_show network.service ActiveState'
    );
is_deeply(
    $unit->get_unit_show('network.service', 'WantedBy'),
    ['multi-user.target', 'graphical.target'],
    'get_unit_show network.service WantedBy'
    );

=pod

=head2 is_active

Test is_active

=cut

# TODO test the looping / mapping?

$cmp->{ERROR} = 0;

# ceph021 output
# active
ok($unit->is_active('ncm-cdispd.service'),
   'is_active Active ncm-cdispd.service (SYSV) is active');

# inactive
ok(! $unit->is_active('tmp.mount'),
   'is_active Inactive tmp.mount is not active');

# inactive but active trigger
is($unit->get_unit_show('cups.service', 'ActiveState'),
   'inactive',
   'get_unit_show cups.service ActiveState'
    );
ok($unit->is_active('cups.service'),
   'is_active Inactive cups.service has active trigger and is thus considered active');

# failed
ok(! $unit->is_active('rc-local.service'),
   'is_active Failed rc-local.service is not active');

# Force a reloading service.
# This is from helper.pm
use cmddata;
my $cmdshort = 'gen_full_el7_ceph021_systemctl_show_xinetd.service_units';
my $cmdline= $cmddata::cmds{$cmdshort}{cmd};
my $out=$cmddata::cmds{$cmdshort}{out};
$out =~ s/^ActiveState\s*=.*$/ActiveState=reloading/m;
set_desired_output($cmdline, $out);

# Force reloading the cache; retrials will always give same answer
# and then static mapping will kick in.
ok($unit->is_active('xinetd.service', force => 1),
   'is_active Reloading xinetd.service is mapped to active');

$out =~ s/^ActiveState\s*=.*$/ActiveState=activating/m;
set_desired_output($cmdline, $out);
ok($unit->is_active('xinetd.service', force => 1),
   'is_active Activating xinetd.service is mapped to active');

$out =~ s/^ActiveState\s*=.*$/ActiveState=deactivating/m;
set_desired_output($cmdline, $out);
ok(! $unit->is_active('xinetd.service', force => 1),
   'is_active Deactivating xinetd.service is mapped to inactive');

is($cmp->{ERROR}, 0, "No errors logged for known ActiveStates");

$out =~ s/^ActiveState\s*=.*$/ActiveState=unkown/m;
set_desired_output($cmdline, $out);
ok(! defined($unit->is_active('xinetd.service', force => 1)),
   'is_active Unknown ActiveState returns undef');
is($cmp->{ERROR}, 1, "Error logged for unknown ActiveState");

# restore
$out =~ s/^ActiveState\s*=.*$/ActiveState=active/m;
set_desired_output($cmdline, $out);

=pod

=head2 get_ufstate

Test get_ufstate

=cut

my ($ufstate, $derived) = $unit->get_ufstate('xinetd.service');
is($ufstate, $STATE_ENABLED, 'get_ufstate xinetd.service UnitFileState is $STATE_ENABLED');
is($derived, $STATE_ENABLED, 'get_ufstate xinetd.service derived state is $STATE_ENABLED');

is($unit->get_unit_show('network.service', 'UnitFileState'),
   '', 'get_unit_show network.service UnitFileState');
($ufstate, $derived) = $unit->get_ufstate('network.service');
is($ufstate, $STATE_ENABLED, "get_ufstate network.service UnitFileState is empty string and is-enabled is $STATE_ENABLED");
is($derived, $STATE_ENABLED, "get_ufstate network.service derived state is $STATE_ENABLED");

is($unit->get_unit_show('-.mount', 'UnitFileState'),
   '', 'get_unit_show -.mount UnitFileState');
($ufstate, $derived) = $unit->get_ufstate('-.mount');
is($ufstate, '', "get_ufstate -.mount UnitFileState is empty string and is-enabled is empty");
is($derived, $STATE_ENABLED, "get_ufstate -.mount derived state is $STATE_ENABLED");

=pod

=head2 is_ufstate

Test is_ufstate

=cut

# test derived logic
# see -.mount states
ok($unit->is_ufstate('-.mount', $STATE_ENABLED),
   "-.mount has ufstate $STATE_ENABLED (via derived)");
ok(!$unit->is_ufstate('-.mount', $STATE_ENABLED, derived => 0),
   "-.mount has not ufstate $STATE_ENABLED (no derived)");

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
        ok($unit->is_ufstate('xinetd.service', $state,  force => 1),
           "is_ufstate for ufstate $ufstate and state $state");
    }

    foreach my $state (@notok) {
        ok(! $unit->is_ufstate('xinetd.service', $state,  force => 1),
           "is_ufstate not for ufstate $ufstate and state $state");
    }
}

# Reset value to original
$out =~ s/^UnitFileState\s*=.*$/UnitFileState=enabled/m;
set_desired_output($cmdline, $out);


=pod

=head2 current_units

Get units via the make_cache_alias

=cut
$cmp->{ERROR} = 0;
my $name;
my $cus = $unit->current_units();

is($cmp->{ERROR}, 0, 'No errors while processing current_units');

is(scalar keys %$cus, 384,
   'Found 384 non-alias units via current_units');

$name = 'nrpe.service';
$svc = $cus->{$name};
is($svc->{name}, $name, "Unit $name name matches");
is($svc->{state}, $STATE_ENABLED, "Unit $name state enabled");
ok(!defined($svc->{derived}), "Unit $name state is not derived");
is($svc->{type}, $TYPE_SERVICE, "Unit $name type $TYPE_SERVICE");
is($svc->{shortname}, "nrpe", "Shortname unit $name type sysv is nrpe");
ok($svc->{startstop}, "Unit $name startstop true");
is_deeply($svc->{targets}, ["multi-user.target"], "Unit $name targets");

# on, but failed to start
$name = 'rc-local.service';
$svc = $cus->{$name};
is($svc->{name}, $name, "Unit $name name matches");
is($svc->{state}, 'static', "Unit $name state static");
ok(!defined($svc->{derived}), "Unit $name state is not derived");
is($svc->{type}, $TYPE_SERVICE, "Unit $name type $TYPE_SERVICE");
is($svc->{shortname}, "rc-local", "shortname unit $name type service is rc-local");
ok($svc->{startstop}, "Unit $name startstop true");
is_deeply($svc->{targets}, ["multi-user.target"], "Unit $name targets");

# sysv service, no UnitFileState (no [Install]), derived state
$name = 'network.service';
$svc = $cus->{$name};
is($svc->{name}, $name, "Unit $name name matches");
is($svc->{state}, $STATE_ENABLED, "Unit $name state enabled");
ok(!defined($svc->{derived}), "Unit $name state not derived");
is($svc->{type}, $TYPE_SERVICE, "Unit $name type $TYPE_SERVICE");
is($svc->{shortname}, "network", "shortname unit $name type service is network");
ok($svc->{startstop}, "Unit $name startstop true");
is_deeply($svc->{targets}, ["multi-user.target", "graphical.target"], "Unit $name targets");

$name = '-.mount';
$svc = $cus->{$name};
is($svc->{name}, $name, "Unit $name name matches");
is($svc->{state}, $STATE_ENABLED, "Unit $name state enabled");
is($svc->{derived}, 1, "Unit $name state is derived");
is($svc->{type}, $TYPE_MOUNT, "Unit $name type $TYPE_SERVICE");
is($svc->{shortname}, "-", "shortname unit $name type service is network");
ok($svc->{startstop}, "Unit $name startstop true");
is_deeply($svc->{targets}, [], "Unit $name targets");

=pod

=head2 configured_services

Test configured services

=cut

my $mockuf = Test::MockModule->new('NCM::Component::Systemd::UnitFile');
my @uf_write;
$mockuf->mock("write", sub {
    my $self = shift;
    # also tested by the getTree call
    isa_ok($self->{config}, 'EDG::WP4::CCM::CacheManager::Element',
           "config on write for $self->{unit} is an Element instance");
    push(@uf_write, [$self->{unit}, $self->{replace}, $self->{backup}, $self->{config}->getTree(), $self->{custom}]);
    return $self->{unit} =~ m/other/ ? 1 : 0;
});

command_history_reset();
my $cfg = get_config_for_profile('service-unit_services');
my $tree = $unit->_getTree($cfg, '/software/components/systemd/unit');
my $cos = $unit->configured_units($tree);
is_deeply($cos->{'test2_on.service'}, {
        name => 'test2_on.service',
        state => $STATE_ENABLED,
        targets => ["rescue.target", "multi-user.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "test2_on",
        possible_missing => 0,
}, "configured_units set correct name and type for test2_on.service");

is_deeply($cos->{'test2_add.target'}, {
        name => "test2_add.target",
        state => $STATE_DISABLED,
        targets => ["multi-user.target"],
        startstop => 1,
        type => $TYPE_TARGET,
        shortname => "test2_add",
        possible_missing => 0,
}, "configured_units set correct name and type for test2_add.target");

is_deeply($cos->{'othername2.service'}, {
        name => "othername2.service",
        state => $STATE_ENABLED,
        targets => ["multi-user.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "othername2",
        possible_missing => 0,
}, "configured_units set correct name and type for othername2.service");

is_deeply($cos->{'test_4_no_restart.service'}, {
        name => "test_4_no_restart.service",
        state => $STATE_ENABLED,
        targets => ["multi-user.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "test_4_no_restart",
        possible_missing => 0,
}, "configured_units set correct name and type for test_4_no_restart.service");

is_deeply($cos->{'test_off.service'}, {
        name => "test_off.service",
        state => $STATE_MASKED,
        targets => ["rescue.target"],
        startstop => 1,
        type => $TYPE_SERVICE,
        shortname => "test_off",
        possible_missing => 1,
}, "configured_units set correct name and type for test_off.service");

is_deeply($cos->{'test_del.service'}, {
        name => "test_del.service",
        state => $STATE_ENABLED,
        targets => ["rescue.target"],
        startstop => 0,
        type => $TYPE_SERVICE,
        shortname => "test_del",
        possible_missing => 0,
}, "configured_units set correct name and type for test_del.service");


# the configured othername2 is a renamed unit, this also shows that the unit->name is used for unitfilename
is_deeply(\@uf_write, [
              ['othername2.service', 1, '.old', {service => {some1 => "data1"}}, {a1 => 'b1'}],
              ['test3_only.service', 0, '.old', {service => {some => "data"}}, {a => 'b'}],
              ['test_4_no_restart.service', 1, '.old', {service => {some1 => "data1"}, unit => {RefuseManualStart => 1}}, {a1 => 'b1'}],
          ], "configured unitfiles initialized as expected");

# the entries in uf_write show that these have a file/ subtree
ok($cos->{$uf_write[0]->[0]}, "service with file/only=0 is added as configured unit");
ok(! defined($cos->{$uf_write[0]->[1]}),
   "service with file/only=1 is not added to the configured units");

ok(command_history_ok(
       ["$SYSTEMCTL try-restart -- othername2.service"],
       ['test3'], # not modified, no try-restart
       ['test_4_no_restart'], # try-restart suppressed
   ), "expected commands for changed unitfile");

=pod

=head2 possible_missing

Test possible_missing

=cut

is($cos->{'test_off.service'}->{state}, $STATE_MASKED, "test_off.service is $STATE_MASKED (and should be possible missing)");
my $pm = $unit->possible_missing($cos);
is_deeply($pm, [qw(test_off.service)], "Found possible missing units");

=pod

=head2 make_cache_alias with units that are usable but not listed

=cut

# set command output for list-unit / list-unit-files to EL7 output of services only
# the netconsole.service is not listed here
$cmdshort = "systemctl_list_unit_files_service";
$cmdline= $cmddata::cmds{$cmdshort}{cmd};
$out=$cmddata::cmds{$cmdshort}{out};
$cmdline =~ s/\s+--type.*$//;
set_desired_output($cmdline, $out);

$cmdshort = "systemctl_list_units_service";
$cmdline= $cmddata::cmds{$cmdshort}{cmd};
$out=$cmddata::cmds{$cmdshort}{out};
$cmdline =~ s/\s+--type.*$//;
set_desired_output($cmdline, $out);

# netconsole.service has no show output
set_desired_output("/usr/bin/systemctl --no-pager --all show -- netconsole.service", "");

# reset the cache
$unit->init_cache();
$cmp->{ERROR} = 0;

($cache, $alias) = $unit->make_cache_alias(['netconsole.service']);
ok(! defined($cache->{'netconsole.service'}),
   "no cache after unknown service (not listed, no show)");
is($cmp->{ERROR}, 1, "an error was reported when handling unknown service (not listed, no show)");

# set as possible missing
$unit->init_cache();
$cmp->{ERROR} = 0;

($cache, $alias) = $unit->make_cache_alias(['netconsole.service'], ['netconsole.service']);
ok(! defined($cache->{'netconsole.service'}),
   "no cache after unknown service (not listed, no show, possible missing)");
is($cmp->{ERROR}, 0, "no error was reported when handling unknown service (not listed, no show, possible missing)");

# minimal show data
my $netconsole_show = <<EOF;
Id=netconsole.service
Names=netconsole.service
EOF

# netconsole.service has show output
set_desired_output("/usr/bin/systemctl --no-pager --all show -- netconsole.service", $netconsole_show);

# reset the cache
$unit->init_cache();
$cmp->{ERROR} = 0;

($cache, $alias) = $unit->make_cache_alias(['netconsole.service']);
ok($cache->{'netconsole.service'}->{showonly},
   'showonly cache attribute set when handling unknown service (not listed, with show)');
is_deeply($cache->{'netconsole.service'}->{show}, {
    Id => 'netconsole.service',
    Names => ['netconsole.service'],
}, "cache after unknown service (not listed, with show)");
is($cmp->{ERROR}, 0, "no error was reported when handling unknown service (not listed, with show)");

# also with netconsole as possible_missing service
($cache, $alias) = $unit->make_cache_alias(['netconsole.service'], ['netconsole.service']);
ok($cache->{'netconsole.service'}->{showonly},
   'showonly cache attribute set when handling unknown service (not listed, with show, possible_missing)');
is_deeply($cache->{'netconsole.service'}->{show}, {
    Id => 'netconsole.service',
    Names => ['netconsole.service'],
}, "cache after unknown service (not listed, with show, possible_missing)");
is($cmp->{ERROR}, 0, "no error was reported when handling unknown service (not listed, with show, possible_missing)");

done_testing();
