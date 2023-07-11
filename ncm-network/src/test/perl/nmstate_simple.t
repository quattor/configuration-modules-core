use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(nmstate_simple);
use Test::MockModule;

use NCM::Component::nmstate;
my $mock = Test::MockModule->new('NCM::Component::nmstate');

my $cfg = get_config_for_profile('nmstate_simple');
my $cmp = NCM::Component::nmstate->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

# From here, test custom methods
command_history_reset();
$cmp->disable_nmstate(1);
# check there a executed commands that match NetworkManager
ok(command_history_ok(undef, ['nmstate']));

done_testing();
