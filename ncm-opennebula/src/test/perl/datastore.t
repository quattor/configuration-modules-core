# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(datastore);
use NCM::Component::opennebula;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;
use Data::Dumper;

use OpennebulaMock;

$CAF::Object::NoAction = 1;


my $cmp = NCM::Component::opennebula->new("datastore");

my $cfg = get_config_for_profile("datastore");
my $tree = $cfg->getElement("/software/components/opennebula")->getTree();
my $one = $cmp->make_one($tree->{rpc});

# Test datastore
ok(exists($tree->{datastores}), "Found datastore data");

rpc_history_reset;
$cmp->manage_something($one, "datastore", $tree->{datastores});
ok(rpc_history_ok(["one.datastorepool.info",
                   "one.datastore.info",
                   "one.datastore.update"]),
                   "manage_something datastore rpc history ok");

ok(!exists($cmp->{ERROR}), "No errors found during datastore management execution");

done_testing();
