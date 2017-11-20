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
set_output('keystone_db_version_missing');
ok($cmp->Configure($cfg), 'Configure returns success');
ok(!exists($cmp->{ERROR}), "No errors found in normal execution");

# Check OpenRC script file
my $fhopenrc = get_file("/root/admin-openrc.sh");
isa_ok($fhopenrc, "CAF::FileWriter", "admin-openrc.sh CAF::FileWriter instance");
like("$fhopenrc", qr{^export\s{1}OS_AUTH_URL\=\'http\://controller.mysite.com:35357/v3\'$}m,
    "admin-openrc.sh has expected content");
$fhopenrc->close();

my $fh = get_file("/etc/keystone/keystone.conf");
# Only test one entry, the remainder lines
# are verified by TT unittests
isa_ok($fh, "CAF::FileWriter", "keystone.conf CAF::FileWriter instance");
like("$fh", qr{^\[database\]$}m, "keystone.conf has expected content");
$fh->close();


diag "all history commands ", explain \@Test::Quattor::command_history;

ok(command_history_ok([
       'service httpd restart',
       '/usr/bin/keystone-manage dbsync',
       '/usr/bin/keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone',
       '/usr/bin/keystone-manage credential_setup --keystone-user keystone --keystone-group keystone',
       '/usr/bin/keystone-manage bootstrap --bootstrap-admin-url http://controller.mysite.com:35357/v3/ --bootstrap-internal-url http://controller.mysite.com:35357/v3/ --bootstrap-password admingoodpass --bootstrap-public-url http://controller.mysite.com:5000/v3/ --bootstrap-region-id RegionOne',
       'service httpd restart',
                      ]), "expected commands run");

command_history_reset();
set_output('keystone_db_version');
ok($cmp->Configure($cfg), 'Configure returns success 2nd');
ok(!exists($cmp->{ERROR}), "No errors found in normal execution 2nd");
ok(command_history_ok(['manage db_version'],['dbsync', 'restart']),
                      "No dbsync or service restart commands called on 2nd run");


done_testing();
