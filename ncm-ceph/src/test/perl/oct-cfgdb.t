use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Quattor qw(oct_cluster);
use NCM::Component::Ceph::Octopus;
use NCM::Component::Ceph::Orchestrator;
use cfgdata;

my $cfg = get_config_for_profile("oct_cluster");

my $cmp = NCM::Component::Ceph::Octopus->new('ceph');
my $cl = NCM::Component::Ceph::Orchestrator->new($cfg, $cmp);
my $cfgdb = NCM::Component::Ceph::CfgDb->new($cl, $cl->{tree}->{configdb});
isa_ok($cl, 'NCM::Component::Ceph::Orchestrator', 'got Orchestrator instance');
isa_ok($cfgdb, 'NCM::Component::Ceph::CfgDb', 'got CfgDb instance');

set_desired_output("/usr/bin/ceph -f json config dump", $cfgdata::CONFJSON);
$cfgdb->parse_profile_cfg();
cmp_deeply($cfgdb->{quattor}, \%cfgdata::PROFILE_CFG, 'profile hash correct');

$cfgdb->get_existing_cfg();
cmp_deeply($cfgdb->{ceph}, \%cfgdata::CONF_HASH, 'ceph hash correct');

$cfgdb->compare_config_maps();
cmp_deeply($cfgdb->{deploy}, \%cfgdata::DEPLOY_CFG, 'deploy hash correct');


my $cfgmap = $cfgdb->get_deploy_config();
cmp_deeply($cfgmap, \%cfgdata::DEPLOY_CFG, 'deploy hash correct');

ok($cl->deploy_config($cfgmap), 'config deployment ok');

ok(get_command('/usr/bin/ceph -f json config set global op_queue wpq'), 'op_queue set');
ok(get_command('/usr/bin/ceph -f json config set global mon_osd_down_out_subtree_limit rack'), 'subtree_limit set');
ok(get_command('/usr/bin/ceph -f json config set mds mds_max_purge_ops_per_pg 10'), 'mds_max_purge_ops_per_pg set');
ok(get_command('/usr/bin/ceph -f json config set mgr mgr/dashboard/server_addr localhost'), 'mgr/dashboard/server_addr set');
ok(get_command('/usr/bin/ceph -f json config set mgr mgr/telemetry/contact me'), 'mgr/telemetry/contact set');
done_testing();
