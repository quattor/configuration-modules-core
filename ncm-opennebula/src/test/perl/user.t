# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(user);
use CAF::Object;

use OpennebulaMock;
use NCM::Component::opennebula;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::opennebula->new("user");

my $cfg = get_config_for_profile("user");
my $tree = $cfg->getElement("/software/components/opennebula")->getTree();
my $one = $cmp->make_one($tree->{rpc});

# Test users
ok(exists($tree->{users}), "Found user data");

rpc_history_reset;
$cmp->manage_something($one, "user", $tree->{users});
#diag_rpc_history;
ok(rpc_history_ok(["one.userpool.info",
                   "one.user.info",
                   "one.user.update"]),
                   "manage_something users rpc history ok");
ok(!exists($cmp->{ERROR}), "No errors found during user management execution");

done_testing();
