# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(opennebula);
use NCM::Component::opennebula;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;
use Data::Dumper;

use OpennebulaMock;

$CAF::Object::NoAction = 1;


my $cmp = NCM::Component::opennebula->new("opennebula");

my $cfg = get_config_for_profile("opennebula");
my $tree = $cfg->getElement("/software/components/opennebula")->getTree();
my $one = $cmp->make_one($tree->{rpc});

# Test datastore
ok(exists($tree->{datastores}), "Found datastore data");

$cmp->manage_something($one, "datastore", $tree->{datastores});
ok(!exists($cmp->{ERROR}), "No errors found during datastore management execution");

done_testing();
