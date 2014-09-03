# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(vnets);
use NCM::Component::opennebula;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;
use OpennebulaMock;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::opennebula->new("opennebula");

my $cfg = get_config_for_profile("vnets");

$cmp->Configure($cfg);
#my $ttout = $cmp->process_template($cfg, "vnet");
#like($ttout, qr{^NAME\s+=\s+}m, "Found vnet NAME");

ok(!exists($cmp->{ERROR}), "No errors found in normal execution");

done_testing();
