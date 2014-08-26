# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(base);
use NCM::Component::opennebula;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::opennebula->new("opennebula");

my $cfg = get_config_for_profile("base");

$cmp->Configure($cfg);
ok(!exists($cmp->{ERROR}), "No errors found in normal execution");

done_testing();
