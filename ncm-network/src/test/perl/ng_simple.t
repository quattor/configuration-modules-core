use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(ng_simple);
use Test::MockModule;

use NCM::Component::network_ng;
my $mock = Test::MockModule->new('NCM::Component::network_ng');

my $cfg = get_config_for_profile('ng_simple');
my $cmp = NCM::Component::network_ng->new('network');


is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

# From here, test custom methods
command_history_reset();
$cmp->disable_networkmanager(1);
# check there a executed commands that match NetworkManager
ok(command_history_ok(undef, ['NetworkManager']));


done_testing();
