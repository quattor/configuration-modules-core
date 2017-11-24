use strict;
use warnings;

use Test::Quattor qw(service);
use Test::Quattor::Object;
use Test::More;

use NCM::Component::OpenStack::Service qw(get_flavour get_service);

use helper;
use Test::Quattor::TextRender::Base;

my $caf_trd = mock_textrender();
my $obj = Test::Quattor::Object->new();

my $cfg = get_config_for_profile("service");

=head2 init new Service

=cut

# This is not the correct way to use Service; only for testing purposes
my $srv = NCM::Component::OpenStack::Service->new("identity", $cfg, $obj, undef, "shouldbeinstance");
isa_ok($srv, 'NCM::Component::OpenStack::Service', 'created a NCM::Component::OpenStack::Service instance');
is($srv->{type}, 'identity', 'type attribute found');
is($srv->{config}, $cfg, 'config attribute found');
is($srv->{prefix}, '/software/components/openstack', 'prefix attribute found');
is($srv->{log}, $obj, 'log attribute found');
is($srv->{client}, 'shouldbeinstance', '(fake) client attribute found');
is($srv->{fqdn}, 'controller.mysite.com', 'fqdn attribute found');
is_deeply([sort keys %{$srv->{comptree}}], [qw(
    compute dashboard hypervisor identity
    network openrc storage)], "comptree attribute found");
is($srv->{flavour}, 'keystone', 'flavour attribute found');
my $flakeys = [qw(database)];
# this also tests the reset on the element
is($srv->{elpath}, "$srv->{prefix}/$srv->{type}/$srv->{flavour}", "elpath attribute");
is_deeply([sort keys %{$srv->{element}->getTree}], $flakeys, "element attribute found");
is_deeply([sort keys %{$srv->{tree}}], $flakeys, "tree attribute found");

is($srv->{filename}, "/etc/keystone/keystone.conf", "filename attribute found");
is($srv->{tt}, 'common', "tt attribute");

is_deeply($srv->{manage}, "/usr/bin/keystone-manage",
          "manage attribute command");

is($srv->{user}, "keystone", "user attribute");
is_deeply($srv->{daemons}, [] , "daemons attribute");


=head2 get_flavour

=cut

is(get_flavour('identity', $srv->{comptree}, $obj), "keystone",
   "get_flavour returned correct flavour");
ok(!defined(get_flavour('identityy', $srv->{comptree}, $obj)),
   "get_flavour returns undef for unknown type");

=head2 get_service

=cut

$srv = get_service("identity", $cfg, $obj, undef, "shouldbeinstance");
isa_ok($srv, 'NCM::Component::OpenStack::Keystone', 'created a NCM::Component::OpenStack::Keystone instance');
isa_ok($srv, 'NCM::Component::OpenStack::Service', 'Keystone instance is a Service instance');

done_testing;
