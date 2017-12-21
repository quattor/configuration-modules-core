use strict;
use warnings;

use Test::More;
use Test::Quattor qw(configure);
use Test::Quattor::Object;
use NCM::Component::ceph;
use cfgdata;
use cluster;

my $cfg = get_config_for_profile("configure");

my $cmp = NCM::Component::ceph->new('ceph');
isa_ok($cmp, 'NCM::Component::ceph', 'got ncm-ceph instance');

set_desired_output('/usr/bin/ceph -f json --version', $cluster::CEPH_VERSION);
ok($cmp->Configure($cfg), 'Ceph component configure ok');

my $fh = get_file('/etc/ceph/ceph.conf');
is("$fh", $cfgdata::CFGFILE_OUT, 'cfgfile ok');

done_testing();
