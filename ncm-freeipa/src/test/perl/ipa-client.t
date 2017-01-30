use strict;
use warnings;

use mock_rpc;

use Test::Quattor;
use Test::More;

use NCM::Component::FreeIPA::Client;

my $c = NCM::Component::FreeIPA::Client->new("host.example.com");

isa_ok($c, 'NCM::Component::FreeIPA::Client', "NCM::Component::FreeIPA::Client instance returned");
isa_ok($c, 'Net::FreeIPA', "NCM::Component::FreeIPA::Client is a Net::FreeIPA instance");


# unmock JSON::XS for Cover
$mock_rpc::json->unmock_all();
done_testing();
