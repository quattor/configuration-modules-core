use strict;
use warnings;

use Test::More;
use Test::Quattor qw(oct_configure);
use NCM::Component::Ceph::Octopus;
use cfgdata;
use clusterdata;
use orchdata;

my $cfg = get_config_for_profile("oct_configure");


my $cmp = NCM::Component::Ceph::Octopus->new('ceph');
isa_ok($cmp, 'NCM::Component::Ceph::Octopus', 'got ncm-ceph instance');


set_desired_output('/usr/bin/ceph -f json --version', $clusterdata::CEPH_VERSION_OCT);
set_desired_output('/usr/bin/ceph -f json orch host ls', $orchdata::HOSTS_JSON);
set_desired_output("/usr/bin/ceph -f json config dump",'[]');

ok($cmp->Configure($cfg), 'Ceph component configure ok');

my $fh = get_file('/etc/ceph/ceph.conf');
is("$fh", $cfgdata::MINCFG_OUT, 'cfgfile ok');

done_testing();
