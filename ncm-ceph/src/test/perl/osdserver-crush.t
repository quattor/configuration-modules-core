use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Quattor qw(osdserver);
use NCM::Component::Ceph::OSDserver;
use Test::Quattor::Object;
use NCM::Component::Ceph::Luminous;
use osddata;

my $obj = Test::Quattor::Object->new();
my $cfg = get_config_for_profile("osdserver");

my $cmp = NCM::Component::Ceph::Luminous->new('ceph');
my $cl = NCM::Component::Ceph::OSDserver->new($cfg, $obj, $cmp->prefix());
isa_ok($cl, 'NCM::Component::Ceph::OSDserver', 'got OSDserver instance');

set_desired_output($osddata::GET_CEPH_PVS_CMD, $osddata::OSD_PVS_OUT);
set_desired_output('/usr/bin/ceph -f json osd dump --id bootstrap-osd',  $osddata::OSD_DUMP);

set_command_status("$osddata::CRUSH set-device-class special osd.24", 1);

ok(!$cl->check_classes(), 'check_classes returns when class could not be set');
ok(get_command("$osddata::CRUSH set-device-class hdd osd.27"), "Called set-device-class for osd.27");
ok(get_command("$osddata::CRUSH set-device-class special osd.24"), "Called set-device-class for osd.24");
ok(get_command("$osddata::CRUSH rm-device-class osd.24"), "Called rm-device-class for osd.24");
ok(!get_command("$osddata::CRUSH rm-device-class osd.27"), "rm-device-class for osd.27 not called");

set_command_status("$osddata::CRUSH set-device-class special osd.24", 0);

ok($cl->check_classes(), 'check_classes ok');

# test wrong osd uuid
set_desired_output($osddata::GET_CEPH_PVS_CMD, $osddata::OSD_PVS_OUT_ALT);

my $deployed = $cl->get_deployed_osds();
my $osdmap = $cl->osd_map();
ok(!$cl->get_osd('sdb', $deployed, $osdmap), 'osd sdb not matching uuid');
ok($cl->get_osd('sdd', $deployed, $osdmap), 'osd sdb matching uuid');
ok(!$cl->check_classes(), 'check_classes returns when uuid is not matched');

done_testing();
