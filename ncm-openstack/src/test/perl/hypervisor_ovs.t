use strict;
use warnings;

use Test::More;
use Test::Quattor qw(hypervisor_ovs);
use Test::Quattor::Object;
use Test::MockModule;

use NCM::Component::openstack;
use NCM::Component::OpenStack::Nova;

use helper;
use Test::Quattor::TextRender::Base;

my $caf_trd = mock_textrender();
my $obj = Test::Quattor::Object->new();

my $cmp = NCM::Component::openstack->new("hypervisor_ovs", $obj);
my $cfg = get_config_for_profile("hypervisor_ovs");

set_file('novacephkey');
set_file('cindercephkey');

ok($cmp->Configure($cfg), "Configure hypervisor returns success");
ok(!exists($cmp->{ERROR}), "No errors found in hypervisor normal execution");


# Verify Nova configuration file
my $fh = get_file("/etc/nova/nova.conf");
isa_ok($fh, "CAF::FileWriter", "nova.conf hypervisor CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "nova.conf hypervisor has expected content");

# Verify Neutron configuration file
$fh = get_file("/etc/neutron/neutron.conf");
isa_ok($fh, "CAF::FileWriter", "neutron.conf hypervisor CAF::FileWriter instance");
like("$fh", qr{^\[DEFAULT\]$}m, "neutron.conf hypervisor has expected content");

# Verify Neutron/openvswitch configuration file
$fh = get_file("/etc/neutron/plugins/ml2/openvswitch_agent.ini");
isa_ok($fh, "CAF::FileWriter", "openvswitch_agent.ini hypervisor CAF::FileWriter instance");
like("$fh", qr{^\[agent\]$}m, "openvswitch_agent.ini hypervisor has expected content");

diag "all hypervisor history commands ", explain \@Test::Quattor::command_history;

ok(command_history_ok([
        '/usr/bin/virsh secret-define --file /var/lib/cinder/tmp/secret_ceph.xml',
        '/usr/bin/virsh secret-set-value --secret a5d0dd94-57c4-ae55-ffe0-7e3732a24455 --base64 defgh',
        '/usr/bin/virsh secret-define --file /var/lib/nova/tmp/secret_ceph.xml',
        '/usr/bin/virsh secret-set-value --secret 5b67401f-dc5e-496a-8456-9a5dc40e7d3c --base64 abc',
        'service openstack-nova-compute restart',
        'service neutron-openvswitch-agent restart',
    ]), "expected hypervisor ovs commands run");

command_history_reset();

done_testing();
