use strict;
use warnings;
use Test::More;
use Test::Quattor qw(simple);
use NCM::Component::path;

my $cmp = NCM::Component::path->new('path');
my $cfg = get_config_for_profile('simple');

ok($cmp->Configure($cfg), "Configure returns success");

done_testing();
