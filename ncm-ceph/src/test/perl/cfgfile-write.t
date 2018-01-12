use strict;
use warnings;

use Test::More;
use Test::Quattor qw(cfgfile);
use NCM::Component::Ceph::Cfgfile;
use Test::Quattor::Object;
use NCM::Component::Ceph::Luminous;
use cfgdata;

my $obj = Test::Quattor::Object->new();
my $cfg = get_config_for_profile("cfgfile");

my $cmp = NCM::Component::Ceph::Luminous->new('ceph');
diag $cmp->prefix();
my $cl = NCM::Component::Ceph::Cfgfile->new($cfg, $obj, $cmp->prefix()."/config");
isa_ok($cl, 'NCM::Component::Ceph::Cfgfile', 'got Cfgfile instance');

ok($cl->configure(), 'cfgfile configure ok');

my $fh = get_file('/etc/ceph/ceph.conf');
is("$fh", $cfgdata::CFGFILE_OUT, 'cfgfile ok');

done_testing();
