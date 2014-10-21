# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(vnet);
use NCM::Component::opennebula;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;
use Data::Dumper;

use OpennebulaMock;

$CAF::Object::NoAction = 1;


my $cmp = NCM::Component::opennebula->new("vnet");

my $cfg = get_config_for_profile("vnet");
my $tree = $cfg->getElement("/software/components/opennebula")->getTree();
my $one = $cmp->make_one($tree->{rpc});



# Test vnet
ok(exists($tree->{vnets}), "Found vnet data");

rpc_history_reset;
$cmp->manage_something($one, "vnet", $tree->{vnets});
#diag_rpc_history;
ok(!exists($cmp->{ERROR}), "No errors found during vnet management execution");
ok(rpc_history_ok(["one.vnpool.info",
                   "one.vn.info",
                   "one.vn.update"]),
                   "manage_something vnet rpc history ok");

done_testing();
