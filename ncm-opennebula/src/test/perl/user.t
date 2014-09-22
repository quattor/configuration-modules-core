# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(user);
use NCM::Component::opennebula;
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;
use Data::Dumper;

use OpennebulaMock;

$CAF::Object::NoAction = 1;


my $cmp = NCM::Component::opennebula->new("user");

my $cfg = get_config_for_profile("user");
my $tree = $cfg->getElement("/software/components/opennebula")->getTree();
my $one = $cmp->make_one($tree->{rpc});

# Test kvm host
#diag("Here is the users conf: ", Dumper($tree->{users}));
ok(exists($tree->{hosts}), "Found user data");

$cmp->manage_something($one, "user", $tree->{users});
ok(!exists($cmp->{ERROR}), "No errors found during user management execution");

done_testing();
