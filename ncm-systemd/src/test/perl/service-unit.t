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

use NCM::Component::Systemd::Service::Unit qw(:targets $DEFAULT_TARGET);
is_deeply([$TARGET_DEFAULT, $TARGET_RESCUE, $TARGET_MULTIUSER, $TARGET_GRAPHICAL,
           $TARGET_POWEROFF, $TARGET_REBOOT],
          [qw(default rescue multi-user graphical poweroff reboot)],
          "TARGET names");
is($DEFAULT_TARGET, $TARGET_MULTIUSER, "multiuser is default target");

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

done_testing();
