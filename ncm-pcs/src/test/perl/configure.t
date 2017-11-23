use strict;
use warnings;

use Test::Quattor qw(simple);
use Test::More;
use Test::Quattor::Object;
use NCM::Component::pcs;

my $obj = Test::Quattor::Object->new();

my $cmp = NCM::Component::pcs->new("pcs", $obj);
my $cfg = get_config_for_profile("simple");

ok($cmp->Configure($cfg), "Configure returns ok");


done_testing;
