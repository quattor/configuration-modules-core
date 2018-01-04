use strict;
use warnings;

use Test::More;
use Test::Quattor qw(configure);
use Test::Quattor::Object;
use NCM::Component::ceph;
use cfgdata;
use osddata;
use clusterdata;

my $cfg = get_config_for_profile("configure");

my $cmp = NCM::Component::ceph->new('ceph');
isa_ok($cmp, 'NCM::Component::ceph', 'got ncm-ceph instance');

set_desired_output($osddata::GET_CEPH_PVS_CMD, $osddata::OSD_PVS_OUT);

set_desired_output('/usr/bin/ceph -f json --version', $clusterdata::CEPH_VERSION);
ok($cmp->Configure($cfg), 'Ceph component configure ok');

my $fh = get_file('/etc/ceph/ceph.conf');
is("$fh", $cfgdata::CFGFILE_OUT, 'cfgfile ok');

set_command_status("$osddata::OSD_VOLUME_CREATE/mapper/osd02", 1); 

my @deploydevs = ('mapper/osd01', 'mapper/osd02', 'sdc', 'sde');
my @nodeploydevs = ('sda4', 'sdb', 'sdd');
foreach my $dev (@deploydevs){
    ok(get_command("$osddata::OSD_VOLUME_CREATE/$dev"), "Called deploy for $dev");
}
foreach my $dev (@nodeploydevs){
    ok(!get_command("$osddata::OSD_VOLUME_CREATE/$dev"), "No deploy for $dev");
}


done_testing();
