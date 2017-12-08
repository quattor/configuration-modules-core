use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Quattor qw(osdserver);
use NCM::Component::Ceph::OSDserver;
use Test::Quattor::Object;
use NCM::Component::ceph;
use osddata;

my $obj = Test::Quattor::Object->new();
my $cfg = get_config_for_profile("osdserver");

my $cmp = NCM::Component::ceph->new('ceph');
my $cl = NCM::Component::Ceph::OSDserver->new($cfg, $obj, $cmp->prefix());
isa_ok($cl, 'NCM::Component::Ceph::OSDserver', 'got OSDserver instance');

set_command_status($osddata::BOOTSTRAP_OSD_KEYRING_CMD, 1);
ok(!$cl->is_node_healthy(), 'node not healthy');
set_command_status($osddata::BOOTSTRAP_OSD_KEYRING_CMD, 0);
ok($cl->is_node_healthy(), 'node healthy');
ok(get_command('/usr/bin/ceph -f json status --id bootstrap-osd'), 'ran cluster health command');

set_desired_output($osddata::GET_CEPH_PVS_CMD, $osddata::OSD_PVS_OUT);
cmp_deeply($cl->get_deployed_osds(), \%osddata::OSD_DEPLOYED, 'Deployed OSD fetched');
#diag explain $cl->get_deployed_osds();

set_command_status("$osddata::OSD_VOLUME_CREATE/mapper/osd02", 1);

ok($cl->configure(), 'Deployment of OSD succeeded');

is($cl->{ok_failures},1, 'Number of failures is 1');
my @deploydevs = ('mapper/osd01', 'mapper/osd02', 'sdc', 'sde');
my @nodeploydevs = ('sda4', 'sdb', 'sdd');
foreach my $dev (@deploydevs){
    ok(get_command("$osddata::OSD_VOLUME_CREATE/$dev"), "Called deploy for $dev");
}
foreach my $dev (@nodeploydevs){
    ok(!get_command("$osddata::OSD_VOLUME_CREATE/$dev"), "No deploy for $dev");
}

done_testing();
