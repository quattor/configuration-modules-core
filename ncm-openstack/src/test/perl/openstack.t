# -* mode: cperl -*-
use strict;
use warnings;

use Test::More;
use Test::Quattor qw(openstack);
use Test::Quattor::Object;
use Test::MockModule;

use NCM::Component::openstack;

use helper;
use Test::Quattor::TextRender::Base;

my $caf_trd = mock_textrender();
my $obj = Test::Quattor::Object->new();

my $cmp = NCM::Component::openstack->new("openstack", $obj);
my $cfg = get_config_for_profile("openstack");

# Test OpenStack component
ok($cmp->Configure($cfg), 'Configure returns success');
ok(!exists($cmp->{ERROR}), "No errors found in normal execution");

is($NCM::Component::openstack::KEYSTONE_CONF_FILE, "/etc/keystone/keystone.conf", "expected keystone.conf filename");

# Only test one entry, the remainder lines
# are verified by TT unittests
my $fh = get_file($NCM::Component::openstack::KEYSTONE_CONF_FILE);
isa_ok($fh, "CAF::FileWriter", "keystone.conf CAF::FileWriter instance");
like("$fh", qr{^\[database\]$}m, "keystone.conf has expected content");
$fh->close();

# Check OpenRC script file
my $fhopenrc = get_file($NCM::Component::openstack::OPENRC_ADMIN_SCRIPT);
isa_ok($fhopenrc, "CAF::FileWriter", "admin-openrc.sh CAF::FileWriter instance");
like("$fhopenrc", qr{^export\s{1}OS_AUTH_URL\=\'http\://controller.mysite.com:35357/v3\'$}m,
    "admin-openrc.sh has expected content");
$fhopenrc->close();

done_testing();
