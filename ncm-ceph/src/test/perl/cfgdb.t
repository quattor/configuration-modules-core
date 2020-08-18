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
isa_ok($cl, 'NCM::Component::Ceph::Cluster', 'got Cluster instance');
isa_ok($cfgdb, 'NCM::Component::Ceph::CfgDb', 'got CfgDb instance');

set_desired_output("/usr/bin/ceph -f json config dump", $cfgdata::CONFJSON);
$cfgdb->parse_profile_cfg();
cmp_deeply($cfgdb->{quattor}, \%cfgdata::PROFILE_CFG, 'profile hash correct');

$cfgdb->get_existing_cfg();
cmp_deeply($cfgdb->{ceph}, \%cfgdata::CONF_HASH, 'ceph hash correct');

$cfgdb->compare_config_maps();
cmp_deeply($cfgdb->{deploy}, \%cfgdata::DEPLOY_CFG, 'deploy hash correct');

done_testing();
