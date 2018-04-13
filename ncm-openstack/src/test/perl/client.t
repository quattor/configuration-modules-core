use strict;
use warnings;

use Test::Quattor::Object;
use Test::More;

use NCM::Component::OpenStack::Client qw(set_logger get_client);
use NCM::Component::OpenStack::Openrc;

use helper;
use mock_rest;

# This is actually mocked away and replace by openrc_example
is($NCM::Component::OpenStack::Openrc::CONFIG_FILE, '/root/admin-openrc.sh', 'expected openrc file');


my $obj = Test::Quattor::Object->new();

is(set_logger($obj), $obj, "set_logger returns object");

my $cl = get_client();
diag explain $cl;
isa_ok($cl, 'Net::OpenStack::Client', 'get_client returns a Net::OpenStack::Client instance');
isa_ok($cl->{log}, 'NCM::Component::OpenStack::Logger',
       'get_client returns a NCM::Component::OpenStack::Logger instance');
is($cl->{log}->{reporter}, $obj, "logger set is the logger used");

my $cl2 = get_client();
is($cl2, $cl, "2nd get_client call returns same client instance");

done_testing();
