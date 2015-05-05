use strict;
use warnings;
use Test::More;
use Test::Quattor qw(service-chkconfig_services);

use helper;
use NCM::Component::systemd;
use NCM::Component::Systemd::Service::Chkconfig;
use NCM::Component::Systemd::Service::Unit qw($TYPE_SYSV $TYPE_TARGET :states);
use NCM::Component::Systemd::Systemctl qw(systemctl_show);

use Test::MockModule;
my $mock = Test::MockModule->new ("CAF::Process");

# fake the existence tests for runlevel and who
my $supp_exe = '';
sub test_executable {
    my ($self, $executable) = @_;
    return $executable eq $supp_exe;
  }
$mock->mock ("_test_executable", \&test_executable);


$CAF::Object::NoAction = 1;


# need a logger instance (could also use CAF::Object instance)
my $cmp = NCM::Component::systemd->new('systemd');

=pod

=head1 DESCRIPTION

Test C<NCM::Component::Systemd::Service::Chkconfig> module for systemd.

=head2 new

Test creation of Chkconfig instance

=cut

my $chk = NCM::Component::Systemd::Service::Chkconfig->new(log => $cmp);
isa_ok($chk, "NCM::Component::Systemd::Service::Chkconfig",
        "NCM::Component::Systemd::Service::Chkconfig instance created");

=pod

=head2 is_possible_missing

Test is_possible_missing

=cut

is($chk->is_possible_missing("myunit", $STATE_DISABLED), 1, "State disabled is also possible_missing in chkconfig");
is($chk->is_possible_missing("myunit", $STATE_MASKED), 1, "State masked is possible_missing (same as unit)");
is($chk->is_possible_missing("myunit", "notastate"), 0, "Default is not possible_missing (same as unit)");

=head2 generate_runlevel2target

Test C<generate_runlevel2target> method.

Start with prepainge for an impossible map 
(so we are not testing any actual output form the testing host).

=cut

set_desired_output("/usr/bin/systemctl --no-pager --all show -- runlevel0.target", "Id=poweroff.target");
is(systemctl_show($cmp, "runlevel0.target")->{Id}, "poweroff.target", "target Id level 0 poweroff.target");

# imaginary mapping to runlevel x1 - x5
foreach my $lvl (1..5) {
    set_desired_output("/usr/bin/systemctl --no-pager --all show -- runlevel$lvl.target", "Id=x$lvl.target");
    is(systemctl_show($cmp, "runlevel$lvl.target")->{Id}, "x$lvl.target", "target Id level $lvl x$lvl.target");
}
# broken runlevel
set_desired_output("/usr/bin/systemctl --no-pager --all show -- runlevel6.target", "Noid=false");
ok(!defined(systemctl_show($cmp, "runlevel6.target")->{Id}), "target Id runlevel6 undefined");

is_deeply($chk->generate_runlevel2target(), 
          ["poweroff.$TYPE_TARGET", "x1.$TYPE_TARGET", "x2.$TYPE_TARGET", "x3.$TYPE_TARGET", 
           "x4.$TYPE_TARGET", "x5.$TYPE_TARGET", "reboot.$TYPE_TARGET"], 
          "Generated level2target arraymap");

=head2 convert_runlevels

Test C<convert_runlevels> method.

Start with prepainge for an impossible map 
(so we are not testing any actual output form the testing host).

=cut

is_deeply($chk->convert_runlevels(), ["multi-user.$TYPE_TARGET"], 
            "Test undefined legacy level returns default multi-user.$TYPE_TARGET");
is_deeply($chk->convert_runlevels(''), ["multi-user.$TYPE_TARGET"], 
            "Test empty-string legacy level returns default multi-user.$TYPE_TARGET");

# fake/partial fake
is_deeply($chk->convert_runlevels('0'), ["poweroff.$TYPE_TARGET"], 
            "Test shutdown legacy level returns poweroff.$TYPE_TARGET");
is_deeply($chk->convert_runlevels('1'), ["x1.$TYPE_TARGET"], 
            "Test 1 legacy level returns fake x1.$TYPE_TARGET");
is_deeply($chk->convert_runlevels('234'), ["x2.$TYPE_TARGET", "x3.$TYPE_TARGET", "x4.$TYPE_TARGET"], 
            "Test 234 legacy level returns fake x2.$TYPE_TARGET,x3.$TYPE_TARGET,x4.$TYPE_TARGET");
is_deeply($chk->convert_runlevels('5'), ["x5.$TYPE_TARGET"], 
            "Test 5 legacy level returns fake x5.$TYPE_TARGET");
is_deeply($chk->convert_runlevels('6'), ["reboot.$TYPE_TARGET"], 
            "Test reboot legacy level returns default reboot.$TYPE_TARGET");

is_deeply($chk->convert_runlevels('0123456'), 
            ["poweroff.$TYPE_TARGET", "x1.$TYPE_TARGET", "x2.$TYPE_TARGET", "x3.$TYPE_TARGET", 
             "x4.$TYPE_TARGET", "x5.$TYPE_TARGET", "reboot.$TYPE_TARGET"], 
            "Test 012345 legacy level with fake data"
            );

# realistic tests
my $res = ["poweroff.$TYPE_TARGET", "rescue.$TYPE_TARGET", "multi-user.$TYPE_TARGET", 
           "multi-user.$TYPE_TARGET", "multi-user.$TYPE_TARGET", "graphical.$TYPE_TARGET", 
           "reboot.$TYPE_TARGET"];
foreach my $lvl (0..6) {
    set_output("systemctl_show_runlevel${lvl}_target_el7");
    is(systemctl_show($cmp, "runlevel${lvl}.target")->{Id}, 
       $res->[$lvl], 
       "target Id level $lvl ".$res->[$lvl]
       );
}
# regenerate cache
is_deeply($chk->generate_runlevel2target(), $res, 
            "Regenerated level2target arraymap");

is_deeply($chk->convert_runlevels('0'), ["poweroff.$TYPE_TARGET"], 
            "Test shutdown legacy level returns poweroff.$TYPE_TARGET");
is_deeply($chk->convert_runlevels('1'), ["rescue.$TYPE_TARGET"], 
            "Test 1 legacy level returns rescue.$TYPE_TARGET");
is_deeply($chk->convert_runlevels('234'), ["multi-user.$TYPE_TARGET"], 
            "Test 234 legacy level returns multi-user.$TYPE_TARGET");
is_deeply($chk->convert_runlevels('5'), ["graphical.$TYPE_TARGET"], 
            "Test 5 legacy level returns graphical.$TYPE_TARGET");
is_deeply($chk->convert_runlevels('6'), ["reboot.$TYPE_TARGET"], 
            "Test reboot legacy level returns reboot.$TYPE_TARGET");
is_deeply($chk->convert_runlevels('0123456'), 
            ["poweroff.$TYPE_TARGET", "rescue.$TYPE_TARGET", "multi-user.$TYPE_TARGET", 
             "graphical.$TYPE_TARGET", "reboot.$TYPE_TARGET"], 
            "Test 012345 legacy level returns poweroff,resuce,multi-user,graphical,reboot");

=pod

=head2 current_unitss 

Get units via chkconfig --list

=cut

set_output("chkconfig_list_el7");

my $cus = $chk->current_units();
is(scalar keys %$cus, 5, "Found 5 units via chkconfig");

my ($name, $svc);

$name = "network.service";
$svc = $cus->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state}, $STATE_ENABLED, "Service $name state enabled");
is($svc->{type}, $TYPE_SYSV, "Service $name type TYPE_SYSV");
is($svc->{shortname}, "network", "Shortname service $name type TYPE_SYSV is network");
ok($svc->{startstop}, "Service $name startstop true");
ok(! $svc->{possible_missing}, "Service $name not possible_missing");
is_deeply($svc->{targets}, ["multi-user.$TYPE_TARGET", "graphical.$TYPE_TARGET"], "Service $name targets");

$name = "netconsole.service";
$svc = $cus->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state}, $STATE_DISABLED, "Service $name state disabled");
is($svc->{type}, $TYPE_SYSV, "Service $name type TYPE_SYSV");
is($svc->{shortname}, "netconsole", "Shortname service $name type TYPE_SYSV is netconsole");
ok($svc->{startstop}, "Service $name startstop true");
ok($svc->{possible_missing}, "Service $name possible_missing");
is_deeply($svc->{targets}, ["multi-user.$TYPE_TARGET", "graphical.$TYPE_TARGET"], "Service $name targets");

=pod

=head2 default_runlevel

Test default_runlevel

=cut

# this file has no initdefault, 
# test the readonly  default runlevel this way
set_file('inittab_el7');
is($chk->default_runlevel(), 3, "Return default runlevel 3 when no initdefault is set in inittab");

set_file('inittab_el6_level5');
is($chk->default_runlevel(), 5, "Return initdefault from inittab");

=pod

=head2 default_runlevel

Test default_runlevel

=cut

set_file('inittab_el7');
is($chk->default_runlevel(), 3, "Default runlevel is 3");
is($chk->default_target(), "multi-user.$TYPE_TARGET", "Default target multi-user is the target based on default runlevel 3");


=pod

=head2 current_runlevel

Test current_runlevel

=cut

# runlevel fails, use who
$supp_exe = "/usr/bin/who";
set_desired_output("/usr/bin/who -r","         run-level 4  2014-10-13 19:34");
is($chk->current_runlevel(), 4, "Return runlevel 4 from who -r");
is($chk->current_target(), "multi-user.$TYPE_TARGET", "Target multi-user is the target based on runlevel 4");

# use runlevel
$supp_exe = "/sbin/runlevel";
set_desired_output("/sbin/runlevel","N 2");
is($chk->current_runlevel(), 2, "Return runlevel 2 from runlevel");
is($chk->current_target(), "multi-user.$TYPE_TARGET", "Target multi-user is the target based on runlevel 2");

# both fail, use default
$supp_exe = '';
is($chk->current_runlevel(), $chk->default_runlevel(), "Return runlevel 3 from default runlevel");
is($chk->current_target(), "multi-user.$TYPE_TARGET", "Target multi-user is the target based on runlevel 3");

=pod

=head2 configured_services

Test configured_services

=cut

my $cfg = get_config_for_profile('service-chkconfig_services');
my $tree = $cfg->getElement('/software/components/chkconfig/service')->getTree();
is_deeply($chk->configured_units($tree), {
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
    'test_off.service' => {
        name => "test_off.service",
        startstop => 1,
        state => $STATE_DISABLED,
        targets => ['multi-user.target', "graphical.target"],
        type => $TYPE_SYSV,
        shortname => "test_off",
        possible_missing => 1,
    },
    'test_del.service' => {
        name => "test_del.service",
        startstop => 1,
        state => $STATE_MASKED,
        targets => ['multi-user.target'],
        type => $TYPE_SYSV,
        shortname => "test_del",
        possible_missing => 1,
    },
}, "Converted chkconfig services in new service details");

done_testing();
