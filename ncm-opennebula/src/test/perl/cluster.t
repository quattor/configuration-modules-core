# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(cluster);
use CAF::Object;

use OpennebulaMock;
use NCM::Component::opennebula;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::opennebula->new("cluster");

my $cfg = get_config_for_profile("cluster");
my $tree = $cfg->getElement("/software/components/opennebula")->getTree();
my $one = $cmp->make_one($tree->{rpc});

# Test clusters
ok(exists($tree->{clusters}), "Found cluster data");

rpc_history_reset;
$cmp->manage_something($one, "cluster", $tree->{clusters});
diag_rpc_history;
ok(rpc_history_ok(["one.clusterpool.info",
                   "one.clusterpool.info",
                   "one.cluster.allocate",
                   "one.cluster.info",
                   "one.clusterpool.info"]),
                   "manage_something clusters rpc history ok");
ok(!exists($cmp->{ERROR}), "No errors found during user management execution");

done_testing();
