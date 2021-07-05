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

set_desired_output("/usr/bin/ceph -f json config dump", $cfgdata::CONFJSON);

ok($cl->set_config_db(), 'config deployment ok');

ok(get_command('/usr/bin/ceph -f json config set global op_queue wpq'), 'op_queue set');
ok(get_command('/usr/bin/ceph -f json config set global mon_osd_down_out_subtree_limit rack'), 'subtree_limit set');
ok(get_command('/usr/bin/ceph -f json config set mds mds_max_purge_ops_per_pg 10'), 'mds_max_purge_ops_per_pg set');
ok(get_command('/usr/bin/ceph -f json config set mgr mgr/dashboard/server_addr localhost'), 'mgr/dashboard/server_addr set');
ok(get_command('/usr/bin/ceph -f json config set mgr mgr/telemetry/contact me'), 'mgr/telemetry/contact set');

done_testing();
