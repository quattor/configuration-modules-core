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

=head2 Prepare generate_runlevel2target

Prepare for an impossible map (so we are not testing any actual output form the testing host).

Do this before init, as C<generate_runlevel2target> method is run during init.

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

=head2 new

Test creation of Chkconfig instance

=cut

my $services = {};
my $chk = NCM::Component::Systemd::Service::Chkconfig->new(services => $services, log => $cmp);
isa_ok($chk, "NCM::Component::Systemd::Service::Chkconfig",
        "NCM::Component::Systemd::Service::Chkconfig instance created");

=head2 generate_runlevel2target

Test C<generate_runlevel2target> method.

=cut

is_deeply($chk->generate_runlevel2target(), 
          ["poweroff", "x1", "x2", "x3", "x4", "x5", "reboot"], 
          "Generated level2target arraymap");

done_testing();
