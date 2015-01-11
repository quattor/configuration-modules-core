use strict;
use warnings;
use Test::More;
use Test::Quattor;

use helper;
use NCM::Component::systemd;
use NCM::Component::Systemd::Service::Chkconfig;
use NCM::Component::Systemd::Systemctl qw(systemctl_show);

$CAF::Object::NoAction = 1;

# need a logger instance (could also use CAF::Object instance)
my $cmp = NCM::Component::systemd->new('systemd');

=pod

=head1 DESCRIPTION

Test C<NCM::Component::Systemd::Service::Chkconfig> module for systemd.

=head2 new

Test creation of Chkconfig instance

=cut

my $services = {};
my $chk = NCM::Component::Systemd::Service::Chkconfig->new(services => $services, log => $cmp);
isa_ok($chk, "NCM::Component::Systemd::Service::Chkconfig",
        "NCM::Component::Systemd::Service::Chkconfig instance created");

=head2 generate_runlevel2target

Test C<generate_runlevel2target> method.

Start with prepainge for an impossible map 
(so we are not testing any actual output form the testing host).

=cut

set_desired_output("/usr/bin/systemctl --no-pager --all show runlevel0.target","Id=poweroff.target");
is(systemctl_show($cmp, "runlevel0.target")->{Id}, "poweroff.target", "target Id level 0 poweroff.target");

# imaginary mapping to runlevel x1 - x5
foreach my $lvl (1..5) {
    set_desired_output("/usr/bin/systemctl --no-pager --all show runlevel$lvl.target","Id=x$lvl.target");
    is(systemctl_show($cmp, "runlevel$lvl.target")->{Id}, "x$lvl.target", "target Id level $lvl x$lvl.target");
}
# broken runlevel
set_desired_output("/usr/bin/systemctl --no-pager --all show runlevel6.target","Noid=false");
ok(!defined(systemctl_show($cmp, "runlevel6.target")->{Id}), "target Id runlevel6 undefined");

is_deeply($chk->generate_runlevel2target(), 
          ["poweroff", "x1", "x2", "x3", "x4", "x5", "reboot"], 
          "Generated level2target arraymap");

=head2 convert_runlevels

Test C<convert_runlevels> method.

Start with prepainge for an impossible map 
(so we are not testing any actual output form the testing host).

=cut

is_deeply($chk->convert_runlevels(), ["multi-user"], 
            "Test undefined legacy level returns default multi-user");
is_deeply($chk->convert_runlevels(''), ["multi-user"], 
            "Test empty-string legacy level returns default multi-user");

# fake/partial fake
is_deeply($chk->convert_runlevels('0'), ["poweroff"], 
            "Test shutdown legacy level returns poweroff");
is_deeply($chk->convert_runlevels('1'), ["x1"], 
            "Test 1 legacy level returns fake x1");
is_deeply($chk->convert_runlevels('234'), ["x2", "x3", "x4"], 
            "Test 234 legacy level returns fake x2,x3,x4");
is_deeply($chk->convert_runlevels('5'), ["x5"], 
            "Test 5 legacy level returns fake x5");
is_deeply($chk->convert_runlevels('6'), ["reboot"], 
            "Test reboot legacy level returns default reboot");

is_deeply($chk->convert_runlevels('0123456'), 
            ["poweroff", "x1", "x2", "x3", "x4", "x5", "reboot"], 
            "Test 012345 legacy level with fake data"
            );

# realistic tests
my $res = ["poweroff", "rescue", "multi-user", "multi-user", "multi-user", "graphical", "reboot"];
foreach my $lvl (0..6) {
    set_output("systemctl_show_runlevel${lvl}_target_el7");
    is(systemctl_show($cmp, "runlevel${lvl}.target")->{Id}, 
       $res->[$lvl].".target", 
       "target Id level $lvl ".$res->[$lvl]
       );
}
# regenerate cache
is_deeply($chk->generate_runlevel2target(), $res, 
            "Regenerated level2target arraymap");

is_deeply($chk->convert_runlevels('0'), ["poweroff"], 
            "Test shutdown legacy level returns poweroff");
is_deeply($chk->convert_runlevels('1'), ["rescue"], 
            "Test 1 legacy level returns rescue");
is_deeply($chk->convert_runlevels('234'), ["multi-user"], 
            "Test 234 legacy level returns multi-user");
is_deeply($chk->convert_runlevels('5'), ["graphical"], 
            "Test 5 legacy level returns graphical");
is_deeply($chk->convert_runlevels('6'), ["reboot"], 
            "Test reboot legacy level returns reboot");
is_deeply($chk->convert_runlevels('0123456'), 
            ["poweroff", "rescue", "multi-user", "graphical", "reboot"], 
            "Test 012345 legacy level returns poweroff,resuce,multi-user,graphical,reboot");

=pod

=head2 current_services 

Get services via chkconfig --list                                                                                                                     
                                                                                                                                                      
=cut                                                                                                                                                  


set_output("chkconfig_list_el7");

my $cs = $chk->current_services();
use Data::Dumper;
diag(Dumper($cs));
is(scalar keys %$cs, 5, "Found 5 services via chkconfig");

my ($name, $svc, @targets);

$name = "network";
$svc = $cs->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state},"on", "Service $name state on");
is($svc->{type}, "sysv", "Service $name type sysv");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user", "graphical"], "Service $name targets");

$name = "netconsole";
$svc = $cs->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state},"off", "Service $name state off");
is($svc->{type}, "sysv", "Service $name type sysv");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user", "graphical"], "Service $name targets");

done_testing();
