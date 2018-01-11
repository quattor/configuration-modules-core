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

my $cmp = NCM::Component::Ceph::Luminous->new($cfg);
my $cl = NCM::Component::Ceph::Cluster->new($cfg, $cmp, $cmp->prefix());

set_command_status('su - ceph -c /usr/bin/ceph-deploy --overwrite-conf config pull ceph001.cubone.os',1);
ok($cl->deploy(\%clmapdata::DEPLOY_HASH), 'deployment ok');

ok(get_command('su - ceph -c /usr/bin/ceph-deploy --overwrite-conf config pull ceph001.cubone.os'), 'pulled ceph001 conf');
ok(get_command('su - ceph -c /usr/bin/ceph-deploy --overwrite-conf config pull ceph003.cubone.os'), 'pulled ceph003 conf');
ok(get_command('su - ceph -c /usr/bin/ceph-deploy mon create ceph001.cubone.os'), 'recreated ceph001 mon');
ok(get_command('su - ceph -c /usr/bin/ceph-deploy mon create ceph003.cubone.os'), 'created ceph003 mon');
ok(get_command('su - ceph -c /usr/bin/ceph-deploy mgr create ceph003.cubone.os:ceph003'), 'created ceph003 mgr');
ok(get_command('su - ceph -c /usr/bin/ceph-deploy mds create ceph003.cubone.os:ceph003'), 'created ceph003 mds');

ok(get_file('/home/ceph/ceph.conf'), 'bootstrap config file written');

done_testing();
