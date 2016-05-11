# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(host);
use CAF::Object;

use OpennebulaMock;
use NCM::Component::opennebula;
use commandsMock;

$CAF::Object::NoAction = 1;


my $cmp = NCM::Component::opennebula->new("host");

my $cfg = get_config_for_profile("host");
my $tree = $cfg->getElement("/software/components/opennebula")->getTree();
my $one = $cmp->make_one($tree->{rpc});
# Set ssh multiplex options
$cmp->set_ssh_command(1);

# Test kvm host
ok(exists($tree->{hosts}), "Found host data");

rpc_history_reset;
$cmp->manage_something($one, "kvm", $tree);
#diag_rpc_history;
ok(rpc_history_ok(["one.hostpool.info",
                   "one.host.info",
                   "one.host.enable",
                   "one.datastorepool.info",
                   "one.datastore.info",
                   "one.host.allocate"]),
                   "manage_something host kvm history ok");
ok(!exists($cmp->{ERROR}), "No errors found during host management execution");

done_testing();
