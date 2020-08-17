use strict;
use warnings;

use Test::More;
use Test::Quattor qw(configure);
use Test::Quattor::Object;
use NCM::Component::Ceph::Luminous;
use cfgdata;
use osddata;
use clusterdata;
use clmapdata;

my $cfg = get_config_for_profile("configure");

my $cmp = NCM::Component::Ceph::Luminous->new('ceph');
# not testable with mocked ncm::component yet
# isa_ok($cmp, 'NCM::Component::ceph', 'got ncm-ceph instance');

set_desired_output($osddata::GET_CEPH_PVS_CMD, $osddata::OSD_PVS_OUT);
set_desired_output("/usr/bin/ceph -f json mon dump", $clmapdata::MONJSON);
set_desired_output("/usr/bin/ceph -f json mgr dump", $clmapdata::MGRJSON);
set_desired_output("/usr/bin/ceph -f json mds stat", $clmapdata::MDSJSON);

set_desired_output("/usr/bin/ceph -f json config dump",'[]');

set_desired_output('/usr/bin/ceph -f json --version', $clusterdata::CEPH_VERSION);
set_desired_output('/usr/bin/ceph -f json osd dump --id bootstrap-osd',  $osddata::OSD_DUMP);
set_file_contents($osddata::BOOTSTRAP_OSD_KEYRING, 'key');
set_file_contents($osddata::BOOTSTRAP_OSD_KEYRING_SL, 'key');

set_command_status("$osddata::OSD_VOLUME_CREATE/mapper/osd02 --bluestore", 1); 

my @deploydevs = ('mapper/osd01', 'mapper/osd02', 'sdc');
my @nodeploydevs = ('sda4', 'sdb', 'sdd');

foreach my $dev (@deploydevs){
    set_command_status("blkid -p /dev/$dev", 1); #empty
};
set_command_status("blkid -p /dev/sde", 1); # empty
set_command_status("blkid -p /dev/sdf", 0); #device exists

ok($cmp->Configure($cfg), 'Ceph component configure ok');

isa_ok($cmp, 'NCM::Component::Ceph::Luminous', 'got ncm-ceph Luminous instance');

my $fh = get_file('/etc/ceph/ceph.conf');
is("$fh", $cfgdata::CFGFILE_OUT, 'cfgfile ok');

foreach my $dev (@deploydevs){
    ok(get_command("$osddata::OSD_VOLUME_CREATE/$dev --bluestore"), "Called deploy for $dev");
}
ok(get_command("$osddata::OSD_VOLUME_CREATE/sde --bluestore --dmcrypt"), 
    "Called deploy for sde");

foreach my $dev (@nodeploydevs){
    ok(!get_command("$osddata::OSD_VOLUME_CREATE/$dev --bluestore"), "No deploy for $dev");
}


done_testing();
