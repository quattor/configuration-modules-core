use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
    *CORE::GLOBAL::time = sub { return 12345678;};
}

use Test::More;
use Test::MockModule;
use Test::Quattor qw(rollback);
use NCM::Component::shorewall;
use CAF::Object;

use Test::Quattor::TextRender::Base;

$CAF::Object::NoAction = 1;

my $caf_trd = mock_textrender();

# service variant set to linux_sysv

set_caf_file_close_diff(1);

my $cmp = NCM::Component::shorewall->new('shorewall');

my $cfg = get_config_for_profile('rollback');

# fake failing ccm-fetch
set_command_status('ccm-fetch', 1);
# set contents to trigger move of backup
set_file_contents('/etc/shorewall/policy', 'whatever');

command_history_reset();
ok($cmp->Configure($cfg), "Configure returns success");
is($cmp->{ERROR}, 3, "Configure has ERRORs");

ok(command_history_ok([
   '^shorewall check /etc/shorewall',
   '^shorewall try /etc/shorewall',
   '^ccm-fetch',
   '^shorewall check /etc/shorewall',
   '^shorewall try /etc/shorewall',
   '^ccm-fetch',
]), "shorewall try and ccm-fetch called 2 after changes");


is_deeply($Test::Quattor::caf_path->{cleanup},
          [[['/etc/shorewall/interfaces', undef],{}]], # no original file (because no backup exists), remove it
          "CAF::Path cleanup called once (w/o backup)");

is_deeply($Test::Quattor::caf_path->{move}, [
    [['/etc/shorewall/interfaces', '/etc/shorewall/interfaces.failed.12345678', undef], {}],
    [['/etc/shorewall/policy', '/etc/shorewall/policy.failed.12345678', undef], {}],
    [['/etc/shorewall/policy.quattor.12345678', '/etc/shorewall/policy', ''], {}], # rollback, backup disabled
], "CAF::Path move called during rollback");

diag explain $Test::Quattor::caf_path;

done_testing;
