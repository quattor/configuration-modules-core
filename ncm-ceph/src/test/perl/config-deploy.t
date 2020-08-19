use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Quattor qw(cluster);
use NCM::Component::Ceph::Luminous;
use NCM::Component::Ceph::Cluster;
use cfgdata;

my $cfg = get_config_for_profile("cluster");

my $cmp = NCM::Component::Ceph::Luminous->new('ceph');
my $cl = NCM::Component::Ceph::Cluster->new($cfg, $cmp, $cmp->prefix());
my $cfgdb = NCM::Component::Ceph::CfgDb->new($cl);

set_desired_output("/usr/bin/ceph -f json config dump", $cfgdata::CONFJSON);

my $cfgmap = $cfgdb->get_deploy_config();
cmp_deeply($cfgmap, \%cfgdata::DEPLOY_CFG, 'deploy hash correct');

ok($cl->deploy_config($cfgmap), 'config deployment ok');

ok(get_command('/usr/bin/ceph -f json config set global op_queue wpq'), 'op_queue set');
ok(get_command('/usr/bin/ceph -f json config set global mon_osd_down_out_subtree_limit rack'), 'subtree_limit set');
ok(get_command('/usr/bin/ceph -f json config set mds mds_max_purge_ops_per_pg 10'), 'mds_max_purge_ops_per_pg set');
ok(get_command('/usr/bin/ceph -f json config set mgr mgr/dashboard/server_addr localhost'), 'mgr/dashboard/server_addr set');
ok(get_command('/usr/bin/ceph -f json config set mgr mgr/telemetry/contact me'), 'mgr/telemetry/contact set');

done_testing();
