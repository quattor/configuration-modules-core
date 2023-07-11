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
my %executables;
$mock->mock('_is_executable', sub {diag "executables $_[1] ",explain \%executables;return $executables{$_[1]};});

my $cfg = get_config_for_profile('nmstate_simple');
my $cmp = NCM::Component::nmstate->new('network');

# TODO: there should e no reason for this. we can assume it's there in EL9
$executables{'/usr/bin/hostnamectl'} = 1;

# TODO: why is this still used? can we get rid of doing anything with it?
set_file_contents("/etc/sysconfig/network", 'x' x 100);

set_file_contents("/etc/resolv.conf", 'managed by something else');


is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

# From here, test custom methods
command_history_reset();
$cmp->disable_nmstate(1);
# check there a executed commands that match NetworkManager
ok(command_history_ok(undef, ['nmstate']));

done_testing();
