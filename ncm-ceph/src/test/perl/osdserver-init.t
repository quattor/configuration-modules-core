use strict;
use warnings;

use Test::More;
use Test::Quattor qw(osdserver);
use NCM::Component::Ceph::OSDserver;
use Test::Quattor::Object;

my $obj = Test::Quattor::Object->new();
my $cfg = get_config_for_profile("osdserver");

my $cl = NCM::Component::Ceph::OSDserver->new($cfg, $obj);
isa_ok($cl, 'NCM::Component::Ceph::OSDserver', 'got OSDserver instance');


done_testing();
