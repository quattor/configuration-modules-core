use strict;
use warnings;

use Test::More;
use Test::Quattor qw(cluster);
use NCM::Component::Ceph::Cluster;
use Test::Quattor::Object;

my $obj = Test::Quattor::Object->new();
my $cfg = get_config_for_profile("cluster");

my $cl = NCM::Component::Ceph::Cluster->new($cfg, $obj);
isa_ok($cl, 'NCM::Component::Ceph::Cluster', 'got Cluster instance');


done_testing();
