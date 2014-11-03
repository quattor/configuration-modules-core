# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(opennebula);
use NCM::Component::opennebula;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;

use OpennebulaMock;
#use commandsMock;

$CAF::Object::NoAction = 1;



my $cmp = NCM::Component::opennebula->new("opennebula");

my $cfg = get_config_for_profile("opennebula");
my $tree = $cfg->getElement("/software/components/opennebula")->getTree();
my $one = $cmp->make_one($tree->{rpc});
# Set ssh multiplex options
$cmp->set_ssh_command(1);

# Test ONE RPC component
rpc_history_reset;
$cmp->Configure($cfg);
#diag_rpc_history;
ok(rpc_history_ok(["one.system.version"]), "Configure opennebula rpc endpoint history ok");

ok(!exists($cmp->{ERROR}), "No errors found in normal execution");

done_testing();
