use strict;
use warnings;

use Test::More;
use Test::Quattor qw(oct_cluster);
use NCM::Component::Ceph::Octopus;
use NCM::Component::Ceph::Orchestrator;
use orchdata;

my $cfg = get_config_for_profile("oct_cluster");

my $cmp = NCM::Component::Ceph::Octopus->new('ceph');
my $cl = NCM::Component::Ceph::Orchestrator->new($cfg, $cmp);

isa_ok($cl, 'NCM::Component::Ceph::Orchestrator', 'got Orchestrator instance');

ok($cl->deploy_orch_section("mon"), 'deployed orch section mon ok');
my $fh = get_file('/etc/ceph/orch_mon.yaml');
is("$fh", $orchdata::MON_YAML, 'mon yaml cfgfile ok');
 ok(get_command('/usr/bin/ceph -f json orch apply -i /etc/ceph/orch_mon.yaml'), 'applied mon config');

ok($cl->deploy_orch_section("mgr"), 'deployed orch section mgr ok');
$fh = get_file('/etc/ceph/orch_mgr.yaml');
is("$fh", $orchdata::MGR_YAML, 'mgr yaml cfgfile ok');

ok($cl->deploy_orch_section("mds"), 'deployed orch section mds ok');
$fh = get_file('/etc/ceph/orch_mds.yaml');
is("$fh", $orchdata::MDS_YAML, 'mds yaml cfgfile ok');

ok($cl->deploy_orch_section("osd"), 'deployed orch section osd ok');
$fh = get_file('/etc/ceph/orch_osd.yaml');
is("$fh", $orchdata::OSD_YAML, 'osd yaml cfgfile ok');
ok(get_command('/usr/bin/ceph -f json orch apply -i /etc/ceph/orch_osd.yaml'), 'applied osd config');

ok($cl->deploy_orch_section("hosts"), 'deployed orch section hosts ok');
$fh = get_file('/etc/ceph/orch_hosts.yaml');
is("$fh", $orchdata::HOSTS_YAML, 'hosts yaml cfgfile ok');
 ok(get_command('/usr/bin/ceph -f json orch apply -i /etc/ceph/orch_hosts.yaml'), 'applied hosts config');

done_testing();
