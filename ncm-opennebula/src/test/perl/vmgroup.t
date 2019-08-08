# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(vmgroup);
use CAF::Object;

use OpennebulaMock;
use NCM::Component::opennebula;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::opennebula->new("vmgroup");

my $cfg = get_config_for_profile("vmgroup");
my $tree = $cfg->getElement("/software/components/opennebula")->getTree();
my $one = $cmp->make_one($tree->{rpc});

# Test vmgroup
ok(exists($tree->{vmgroups}), "Found vmgroup data");

rpc_history_reset;
$cmp->manage_something($one, "vmgroup", $tree->{vmgroups});
#diag_rpc_history;
ok(rpc_history_ok(["one.vmgrouppool.info",
                   "one.vmgrouppool.info",
                   "one.vmgroup.allocate",
                   "one.vmgroup.info"]),
                   "manage_something vmgroup rpc history ok");

ok(!exists($cmp->{ERROR}), "No errors found during vmgroup management execution");

done_testing();
