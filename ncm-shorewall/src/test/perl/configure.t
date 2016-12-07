use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
    *CORE::GLOBAL::time = sub { return 12345678;};
}

use Test::More;
use Test::MockModule;
# sysconfig is added here to test valid template
use Test::Quattor qw(basic sysconfig);
use NCM::Component::shorewall;
use CAF::Object;

use Test::Quattor::TextRender::Base;

$CAF::Object::NoAction = 1;

my $caf_trd = mock_textrender();

# service variant set to linux_sysv

set_caf_file_close_diff(1);

my $cmp = NCM::Component::shorewall->new('shorewall');

my $cfg = get_config_for_profile('basic');

command_history_reset();
ok($cmp->Configure($cfg), "Configure returns success");
ok(!exists($cmp->{ERROR}), "Configure succeeds w/o ERROR");

foreach my $fn (qw(shorewall.conf zones rules policy interfaces tcpri tcinterfaces masq)) {
    my $fh = get_file("/etc/shorewall/$fn");
    ok($fh, "filename $fn generated");
    is(*$fh->{options}->{backup}, '.quattor.12345678', "TextRender filewriter with timestamped backup used");
    is(*$fh->{options}->{mode}, 0600, "TextRender filewriter with 0600 mode used");
};


ok(command_history_ok([
   '^shorewall check /etc/shorewall',
   '^shorewall try /etc/shorewall',
   '^ccm-fetch',
]), "shorewall try and ccm-fetch called after changes");

command_history_reset();
ok($cmp->Configure($cfg), "Configure returns success on rerun");
ok(!exists($cmp->{ERROR}), "Configure succeeds w/o ERROR on rerun");
ok(command_history_ok(undef, [qr{sbin/(shorewall|ccm-fetch) try}]),
   "shorewall try and ccm-fetch called not called after rerun (nothing changed)");

done_testing();
