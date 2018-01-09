use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Quattor qw(cluster);
use NCM::Component::Ceph::Luminous;
use NCM::Component::Ceph::Cluster;
use NCM::Component::Ceph::ClusterMap;
use clmapdata;

my $cfg = get_config_for_profile("cluster");

my $cmp = NCM::Component::Ceph::Luminous->new('ceph');
my $cl = NCM::Component::Ceph::Cluster->new($cfg, $cmp, $cmp->prefix());
my $clmap = NCM::Component::Ceph::ClusterMap->new($cl);
isa_ok($clmap, 'NCM::Component::Ceph::ClusterMap', 'got ClusterMap instance');

set_desired_output("/usr/bin/ceph -f json mon dump", $clmapdata::MONJSON);
set_desired_output("/usr/bin/ceph -f json mgr dump", $clmapdata::MGRJSON);
set_desired_output("/usr/bin/ceph -f json mds stat", $clmapdata::MDSJSON);

ok($clmap->map_existing(), 'mapping existing daemons');

cmp_deeply($clmap->{ceph}, \%clmapdata::CEPH_HASH, 'ceph hash correct');


ok($clmap->map_quattor(), 'mapping daemons to configure');
cmp_deeply($clmap->{quattor}, \%clmapdata::QUATTOR_HASH, 'quattor hash correct');

set_command_status("$clmapdata::SSH_FULL ceph001.cubone.os test -e /var/lib/ceph/mon/ceph-ceph001/done", 1);
cmp_deeply($clmap->get_deploy_map(), \%clmapdata::DEPLOY_HASH, 'deploy hash correct');


done_testing();
