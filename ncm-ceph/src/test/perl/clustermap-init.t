use strict;
use warnings;

use Test::More;
use Test::Quattor qw(cluster);
use NCM::Component::Ceph::Cluster;
use NCM::Component::Ceph::ClusterMap;
use Test::Quattor::Object;

my $obj = Test::Quattor::Object->new();
my $cfg = get_config_for_profile("cluster");

my $cl = NCM::Component::Ceph::Cluster->new($cfg, $obj);
my $clmap = NCM::Component::Ceph::ClusterMap->new($cl);
isa_ok($cl, 'NCM::Component::Ceph::Cluster', 'got Cluster instance');
isa_ok($clmap, 'NCM::Component::Ceph::ClusterMap', 'got ClusterMap instance');


done_testing();
