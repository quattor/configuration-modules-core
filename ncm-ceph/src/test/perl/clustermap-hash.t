use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Quattor qw(cluster);
use NCM::Component::ceph;
use NCM::Component::Ceph::Cluster;
use NCM::Component::Ceph::ClusterMap;
use clmap;

my $cfg = get_config_for_profile("cluster");

my $cmp = NCM::Component::ceph->new($cfg);
my $cl = NCM::Component::Ceph::Cluster->new($cfg, $cmp, $cmp->prefix());
my $clmap = NCM::Component::Ceph::ClusterMap->new($cl);
isa_ok($clmap, 'NCM::Component::Ceph::ClusterMap', 'got ClusterMap instance');

set_desired_output("/usr/bin/ceph -f json mon dump", $clmap::MONJSON);
set_desired_output("/usr/bin/ceph -f json mgr dump", $clmap::MGRJSON);
set_desired_output("/usr/bin/ceph -f json mds stat", $clmap::MDSJSON);

ok($clmap->map_existing(), 'mapping existing daemons');

cmp_deeply($clmap->{ceph}, \%clmap::CEPH_HASH, 'ceph hash correct') ;


ok($clmap->map_quattor(), 'mapping daemons to configure');
diag explain $clmap->{quattor};



done_testing();
