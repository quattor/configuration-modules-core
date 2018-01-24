use strict;
use warnings;

use Test::More;
use Test::Quattor qw(cfgfile);
use NCM::Component::Ceph::Cfgfile;
use Test::Quattor::Object;

my $obj = Test::Quattor::Object->new();
my $cfg = get_config_for_profile("cfgfile");

my $cl = NCM::Component::Ceph::Cfgfile->new($cfg, $obj);
isa_ok($cl, 'NCM::Component::Ceph::Cfgfile', 'got Cfgfile instance');


done_testing();
