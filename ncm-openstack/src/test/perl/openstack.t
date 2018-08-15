# -* mode: cperl -*-
use strict;
use warnings;

use Test::More;
use Test::Quattor qw(openstack);
use Test::Quattor::Object;
use Test::MockModule;

use NCM::Component::openstack;

use helper;
use mock_rest qw(openstack);

use Test::Quattor::TextRender::Base;

my $caf_trd = mock_textrender();
my $obj = Test::Quattor::Object->new();


my $cmp = NCM::Component::openstack->new("openstack", $obj);
my $cfg = get_config_for_profile("openstack");

# Test OpenStack component
set_output('keystone_db_version_missing');
set_output('glance_db_version_missing');
set_output('nova_db_version_missing');
set_output('neutron_db_version_missing');
set_output('rabbitmq_db_version_missing');
set_output('cinder_db_version_missing');
set_output('manila_db_version_missing');
set_output('heat_db_version_missing');
set_output('murano_db_version_missing');

ok($cmp->Configure($cfg), 'Configure returns success');
ok(!exists($cmp->{ERROR}), "No errors found in normal execution");

# Check OpenRC script file
my $fhopenrc = get_file("/root/admin-openrc.sh");
isa_ok($fhopenrc, "CAF::FileWriter", "admin-openrc.sh CAF::FileWriter instance");
like("$fhopenrc", qr{^export\s{1}OS_AUTH_URL\=\'http\://controller.mysite.com:35357/v3\'$}m,
    "admin-openrc.sh has expected content");

# Verify Keystone configuration file
my $fh = get_file("/etc/keystone/keystone.conf");
# Only test one entry, the remainder lines
# are verified by TT unittests
isa_ok($fh, "CAF::FileWriter", "keystone.conf CAF::FileWriter instance");
like("$fh", qr{^\[database\]$}m, "keystone.conf has expected content");

# Verify Glance configuration files
$fh = get_file("/etc/glance/glance-api.conf");
isa_ok($fh, "CAF::FileWriter", "glance-api.conf CAF::FileWriter instance");
like("$fh", qr{^\[database\]$}m, "glance-api.conf has expected content");

# Verify Nova configuration files
$fh = get_file("/etc/nova/nova.conf");
isa_ok($fh, "CAF::FileWriter", "nova.conf CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "nova.conf has expected content");

# Verify Neutron configuration files
$fh = get_file("/etc/neutron/neutron.conf");
isa_ok($fh, "CAF::FileWriter", "neutron.conf CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "neutron.conf has expected content");

$fh = get_file("/etc/neutron/plugins/ml2/ml2_conf.ini");
isa_ok($fh, "CAF::FileWriter", "ml2_conf.ini CAF::FileWriter instance");
like("$fh", qr{^\[securitygroup\]$}m, "ml2_conf.ini has expected content");

$fh = get_file("/etc/neutron/plugins/ml2/linuxbridge_agent.ini");
isa_ok($fh, "CAF::FileWriter", "inuxbridge_agent.ini CAF::FileWriter instance");
like("$fh", qr{^\[linux_bridge\]$}m, "inuxbridge_agent.ini has expected content");

$fh = get_file("/etc/neutron/l3_agent.ini");
isa_ok($fh, "CAF::FileWriter", "l3_agent.ini CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "l3_agent.ini has expected content");

$fh = get_file("/etc/neutron/dhcp_agent.ini");
isa_ok($fh, "CAF::FileWriter", "dhcp_agent.ini CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "dhcp_agent.ini has expected content");

$fh = get_file("/etc/neutron/metadata_agent.ini");
isa_ok($fh, "CAF::FileWriter", "metadata_agent.ini CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "metadata_agent.ini has expected content");

# Verify Dashboard configuration file
$fh = get_file("/etc/openstack-dashboard/local_settings");
isa_ok($fh, "CAF::FileWriter", "dashboard local_settings CAF::FileWriter instance");
like("$fh", qr{^\#\s{1}-\*-\s{1}coding:\s{1}utf-8\s{1}-\*-$}m, "local_settings has expected content");

# Verify Cinder configuration file
$fh = get_file("/etc/cinder/cinder.conf");
isa_ok($fh, "CAF::FileWriter", "cinder.conf CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "cinder.conf has expected content");

# Verify Manila configuration file
$fh = get_file("/etc/manila/manila.conf");
isa_ok($fh, "CAF::FileWriter", "manila.conf CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "manila.conf has expected content");

# Verify Heat configuration file
$fh = get_file("/etc/heat/heat.conf");
isa_ok($fh, "CAF::FileWriter", "heat.conf CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "heat.conf has expected content");

# Verify Murano configuration file
$fh = get_file("/etc/murano/murano.conf");
isa_ok($fh, "CAF::FileWriter", "murano.conf CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "murano.conf has expected content");

diag "all servers history commands ", explain \@Test::Quattor::command_history;

ok(command_history_ok([
        'service httpd restart',
        '/usr/sbin/rabbitmqctl list_user_permissions openstack',
        '/usr/sbin/rabbitmqctl add_user openstack rabbit_pass',
        '/usr/sbin/rabbitmqctl set_permissions openstack .* .* .*',
        '/usr/bin/keystone-manage db_version',
        '/usr/bin/keystone-manage db_sync',
        '/usr/bin/keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone',
        '/usr/bin/keystone-manage credential_setup --keystone-user keystone --keystone-group keystone',
        '/usr/bin/keystone-manage bootstrap --bootstrap-admin-url http://controller.mysite.com:35357/v3/ --bootstrap-internal-url http://controller.mysite.com:35357/v3/ --bootstrap-password admingoodpass --bootstrap-public-url http://controller.mysite.com:5000/v3/ --bootstrap-region-id RegionOne',
        'service httpd restart',
        '/usr/bin/glance-manage db_version',
        '/usr/bin/glance-manage db_sync',
        'service openstack-glance-registry restart',
        'service openstack-glance-api restart',
        '/usr/bin/cinder-manage db version',
        '/usr/bin/cinder-manage db sync',
        'service openstack-cinder-api restart',
        'service openstack-cinder-scheduler restart',
        'service openstack-cinder-volume restart',
        '/usr/bin/manila-manage db version',
        '/usr/bin/manila-manage db sync',
        'service openstack-manila-api restart',
        'service openstack-manila-scheduler restart',
        'service openstack-manila-share restart',
        '/usr/bin/nova-manage db version',
        '/usr/bin/nova-manage api_db sync',
        '/usr/bin/nova-manage cell_v2 map_cell0',
        '/usr/bin/nova-manage cell_v2 create_cell --name=cell1 --verbose',
        '/usr/bin/nova-manage db sync',
        'service openstack-nova-api restart',
        'service openstack-nova-consoleauth restart',
        'service openstack-nova-scheduler restart',
        'service openstack-nova-conductor restart',
        'service openstack-nova-novncproxy restart',
        '/usr/bin/neutron-db-manage current',
        '/usr/bin/neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head',
        'service neutron-dhcp-agent restart',
        'service neutron-l3-agent restart',
        'service neutron-linuxbridge-agent restart',
        'service neutron-metadata-agent restart',
        'service neutron-server restart',
        '/usr/bin/heat-manage db_version',
        '/usr/bin/heat-manage db_sync',
        'service openstack-heat-api restart',
        'service openstack-heat-api-cfn restart',
        'service openstack-heat-engine restart',
        '/usr/bin/murano-db-manage version',
        '/usr/bin/murano-db-manage upgrade',
        'service openstack-murano-api restart',
        'service openstack-murano-api-cfn restart',
        'service openstack-murano-engine restart',
        'service httpd restart',
                      ]), "server expected commands run");

diag "method history";
dump_method_history;
ok(method_history_ok([
    'POST .*/v3/auth/tokens',
    'GET .*/regions/  ',
    'POST .*/regions/ .*description":"abc",.*"id":"regionOne"',
    'POST .*/regions/ .*description":"def",.*"id":"regionTwo"',
    'POST .*/regions/ .*description":"xyz",.*"id":"regionThree"',
    'GET .*/domains/  ',
    'POST .*/domains/ .*description":"vo1",.*"name":"vo1"',
    'POST .*/domains/ .*description":"vo2",.*"name":"vo2"',
    'GET .*/projects/  ',
    'POST .*/projects/ .*,"name":"opq"',
    'POST .*/projects/ .*"description":"main vo1 project","domain_id":"dom12345".*"name":"vo1"',
    'POST .*/projects/ .*"description":"main vo2 project","domain_id":"dom23456",.*"name":"vo2"',
    'POST .*/projects/ .*"description":"some real project".*"name":"realproject".*"parent_id":"pro124"',
    'GET .*/users/  ',
    'POST .*/users/ .*"description":"quattor service volume flavour cinder user","domain_id":"dom112233","enabled":true,"name":"cinder","password":"cinder_good_password"',
    'PUT .*/projects/10/tags/ID_user_use12c',
    'POST .*/users/ .*"description":"quattor service storage flavour glance user","domain_id":"dom112233","enabled":true,"name":"glance","password":"glance_good_password"',
    'PUT .*/projects/10/tags/ID_user_use12g',
    'POST .*/users/ .*"description":"quattor service share flavour manila user","domain_id":"dom112233","enabled":true,"name":"manila","password":"manila_good_password"',
    'PUT .*/projects/10/tags/ID_user_use12m',
    'POST .*/users/ .*"description":"quattor service network flavour neutron user","domain_id":"dom112233","enabled":true,"name":"neutron","password":"neutron_good_password"',
    'POST .*/users/ .*"description":"first user",.*"name":"user1","password":"abc"',
    'GET .*/groups/  ',
    'POST .*/groups/ .*"description":"first group","domain_id":"dom23456",.*"name":"grp1"',
    'GET .*/roles/  ',
    'POST .*/roles/ .*"enabled":true,"name":"rl1"',
    'POST .*/roles/ .*"enabled":true,"name":"rl2"',
    'PUT .*/domains/dom12345/users/use12/roles/rll11 \{\} ',
    'PUT .*/projects/10/tags/ROLE_domains%2Fdom12345%2Fusers%2Fuse12%2Froles%2Frll11 \{\}',
    'PUT .*/projects/pro125/groups/use12/roles/rll12 \{\}',
    'PUT .*/projects/pros/users/use12c/roles/rolaaddmm ',
    'PUT .*/projects/pros/users/use12g/roles/rolaaddmm ',
    'PUT .*/projects/pros/users/use12m/roles/rolaaddmm ',
    'PUT .*/projects/pros/users/use12no/roles/rolaaddmm ',
    'GET .*/services/  ',
    'POST .*/services/ .*"description":"OS image one",.*"name":"glanceone","type":"image"',
    'POST .*/services/ .*"description":"OS compute service nova",.*"name":"nova","type":"compute"',
    'POST .*/services/ .*"description":"OS placement service placement",.*"name":"placement","type":"placement"',
]), "REST API calls as expected");

command_history_reset();
set_output('keystone_db_version');
ok($cmp->Configure($cfg), 'Configure returns success 2nd');
ok(!exists($cmp->{ERROR}), "No errors found in normal execution 2nd");
ok(command_history_ok(['manage db_version'],['dbsync', 'restart']),
                      "No dbsync or service restart commands called on 2nd run");


done_testing();
