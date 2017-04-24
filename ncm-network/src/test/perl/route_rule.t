use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(route_rule);

use NCM::Component::network;

use Readonly;

use Test::MockModule;
my $mock = Test::MockModule->new('NCM::Component::network');
my %executables;
$mock->mock('_is_executable', sub {diag "executables $_[1] ",explain \%executables;return $executables{$_[1]};});


Readonly my $NETWORK => <<EOF;
NETWORKING=yes
HOSTNAME=somehost.test.domain
GATEWAY=4.3.2.254
EOF

Readonly my $ETH0 => <<EOF;
ONBOOT=yes
NM_CONTROLLED='no'
DEVICE=eth0
TYPE=Ethernet
BOOTPROTO=static
IPADDR=4.3.2.1
NETMASK=255.255.255.0
BROADCAST=4.3.2.255
EOF

Readonly my $ETH1 => <<EOF;
ONBOOT=yes
NM_CONTROLLED='no'
DEVICE=eth1
TYPE=Ethernet
BOOTPROTO=static
IPADDR=4.3.2.1
NETMASK=255.255.255.0
BROADCAST=4.3.2.255
DEFROUTE=no
IPV6_DEFROUTE=no
EOF

Readonly my $VLAN0 => <<EOF;
ONBOOT=yes
NM_CONTROLLED='no'
DEVICE=eth0.123
TYPE=Ethernet
BOOTPROTO=static
IPADDR=4.3.2.1
NETMASK=255.255.255.0
BROADCAST=4.3.2.255
VLAN=yes
ISALIAS=no
PHYSDEV=eth0
EOF

Readonly my $ETH0_ROUTE => <<EOF;
1.2.3.4/32 dev eth0
1.2.3.5/24 dev eth0
1.2.3.6/8 via 4.3.2.1 dev eth0
1.2.3.7/16 via 4.3.2.2 dev eth0
something arbitrary
EOF

Readonly my $ETH0_ROUTE6 => <<EOF;
0:0:0:0:0:0:0:4/75 dev eth0
0:0:0:0:0:0:0:5/76 via 4::1 dev eth0
something arbitrary with :
EOF

Readonly my $ETH0_RULE => <<EOF;
something
more
EOF

Readonly my $ETH0_RULE6 => <<EOF;
something with ::
more ::
EOF


Readonly my $LEGACY_ETH1_ROUTE => <<EOF;
ADDRESS0=1.2.3.4
NETMASK0=255.255.255.255
EOF

Readonly my $ETH1_ROUTE => <<EOF;
1.2.3.4/32 dev eth1
EOF

Readonly my $VLAN0_ROUTE => <<EOF;
1.2.3.4/32 dev eth0.123
EOF

# File must exist, set with correct content
set_file_contents("/etc/sysconfig/network", $NETWORK);
set_file_contents("/etc/sysconfig/network-scripts/ifcfg-eth0", $ETH0);
set_file_contents("/etc/sysconfig/network-scripts/ifcfg-eth1", $ETH1);
set_file_contents("/etc/sysconfig/network-scripts/route-eth1", $LEGACY_ETH1_ROUTE); # legacy format

my $cfg = get_config_for_profile('route_rule');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

is(get_file_contents("/etc/sysconfig/network-scripts/route-eth0"), $ETH0_ROUTE, "Exact route config");
is(get_file_contents("/etc/sysconfig/network-scripts/route6-eth0"), $ETH0_ROUTE6, "Exact route6 config");
is(get_file_contents("/etc/sysconfig/network-scripts/rule-eth0"), $ETH0_RULE, "Exact rule config");
is(get_file_contents("/etc/sysconfig/network-scripts/rule6-eth0"), $ETH0_RULE6, "Exact rule6 config");

is(get_file_contents("/etc/sysconfig/network-scripts/route-eth1"), $ETH1_ROUTE, "Exact route config eth1");

is(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-vlan0"), $VLAN0, "Exact vlan0 config");
is(get_file_contents("/etc/sysconfig/network-scripts/route-vlan0"), $VLAN0_ROUTE, "Exact route config vlan0");

ok(command_history_ok([
    'ip addr show',
    '/sbin/ifdown eth0',
    '/sbin/ifdown vlan0',
    '/sbin/ifup eth0 boot',
    '/sbin/ifup vlan0 boot',
    'ccm-fetch',
], [
    'service network stop',
    'service network start',
    '/sbin/ifdown eth1',
    '/sbin/ifup eth1',
]), "network stop/start not called with same config; ifdown/ifup eth1 not called (gracefull handling of legacy format)");


done_testing();
