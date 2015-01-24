use strict;
use warnings;
use Test::More;
use Test::Quattor;

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

my $services = {};
my $unit = NCM::Component::Systemd::Service::Unit->new(services => $services, log => $cmp);
isa_ok($unit, "NCM::Component::Systemd::Service::Unit",
        "NCM::Component::Systemd::Service::Unit instance created");

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

=head2 current_services
                                                                                                                                                      
Get services via systemctl list-unit-files --type service                                                                                             
                                                                                                                                                      
=cut                                                                                                                                                  

use cmddata::service_systemctl_list_show_gen_full_el7_ceph021_load;

my $name;
my $cs = $unit->current_services('service');

is(scalar keys %$cs, 133, "Found 133 services via systemctl list-unit-files --type service");

$name = 'nrpe';
$svc = $cs->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state},"on", "Service $name state disabled");
is($svc->{type}, "service", "Service $name type sysv");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user"], "Service $name targets");

# has name ending with @; is off
$name = 'autovt@';
$svc = $cs->{$name};
is($svc->{name}, 'autovt', "Service $name name matches without \@");
is($svc->{state},"off", "Service $name state disabled");
is($svc->{type}, "service", "Service $name type sysv");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, [], "Service $name targets");

# on, but failed to start
$name = 'rc-local';
$svc = $cs->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state},"on", "Service $name state disabled");
is($svc->{type}, "service", "Service $name type sysv");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user"], "Service $name targets");

done_testing();
