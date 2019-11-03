# -*- mode: cperl -*-
use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(simple simple_ethtool simple_noethtool simple_realhostname simple_nobroadcast);
use Test::MockModule;

use NCM::Component::network;
my $mock = Test::MockModule->new('NCM::Component::network');
my %executables;
$mock->mock('_is_executable', sub {diag "executables $_[1] ",explain \%executables;return $executables{$_[1]};});

use Readonly;

Readonly my $RT => <<EOF;
#
# reserved values
#
255	local
254	main
253	default
0	unspec
#
# local
#
#1	inr.ruhep
4 manual
80 someold # managed by Quattor
200 custom
EOF

Readonly my $NETWORK => <<EOF;
NETWORKING=yes
HOSTNAME=somehost.test.domain
GATEWAY=4.3.2.254
EOF

Readonly my $NETWORK_HOSTNAMECTL => <<EOF;
NETWORKING=yes
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

Readonly my $ETHTOOL_ETH0 => <<EOF;
Settings for eth0:
	Supported ports: [ TP ]
	Supported link modes:   10baseT/Half 10baseT/Full 
	                        100baseT/Half 100baseT/Full 
	                        1000baseT/Full 
	Supported pause frame use: Symmetric
	Supports auto-negotiation: Yes
	Supported FEC modes: Not reported
	Advertised link modes:  10baseT/Half 10baseT/Full 
	                        100baseT/Half 100baseT/Full 
	                        1000baseT/Full 
	Advertised pause frame use: Symmetric
	Advertised auto-negotiation: Yes
	Advertised FEC modes: Not reported
	Speed: 1000Mb/s
	Duplex: Full
	Port: Twisted Pair
	PHYAD: 1
	Transceiver: internal
	Auto-negotiation: on
	MDI-X: off (auto)
	Supports Wake-on: pumbg
	Wake-on: d
	Current message level: 0x00000007 (7)
			       drv probe link
	Link detected: yes
EOF

Readonly my $ETHTOOL_ETH0_CHANNELS => <<EOF;
Channel parameters for eth0:
Pre-set maximums:
RX:		0
TX:		0
Other:		1
Combined:	8
Current hardware settings:
RX:		0
TX:		0
Other:		1
Combined:	8
EOF

=head1 DESCRIPTION

Test the C<Configure> method of the component for bridge configuration.

=cut

ok($NETWORK ne $NETWORK_HOSTNAMECTL,
   "expected network config is different for case with and without hostnamectl");

# File must exist
set_file_contents("/etc/sysconfig/network", 'x' x 1000);
set_file_contents("/etc/iproute2/rt_tables", $RT);

my $cfg = get_config_for_profile('simple');
my $cmp = NCM::Component::network->new('network');

set_desired_output('/usr/sbin/ethtool eth0', $ETHTOOL_ETH0);
set_desired_output('/usr/sbin/ethtool --show-channels eth0', $ETHTOOL_ETH0_CHANNELS);

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

is(get_file_contents("/etc/iproute2/rt_tables"), $RT, "Exact (unmodified) routing table");

# generic
my $fh;

$fh = get_file($cmp->testcfg_filename("/etc/sysconfig/network"));
ok(! defined($fh), "testcfg network file was cleaned up");

# on success, this is hardlink of a cleaned up testcfg; can't use get_file
is(get_file_contents("/etc/sysconfig/network"), $NETWORK, "Exact network config");


$fh = get_file($cmp->testcfg_filename("/etc/sysconfig/network-scripts/ifcfg-eth0"));
ok(! defined($fh), "testcfg network/ifcfg-eth0 was cleaned up");

is(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-eth0"), $ETH0, "Exact network config");


ok(command_history_ok([
    'ip addr show',
    '/sbin/chkconfig --level 2345 network on',
    'service network stop',
    'service network start',
    'ccm-fetch',
], ['hostnamectl']),
   "network stop/start called on network config change (and no hostnamectl)");

command_history_reset();

is($cmp->Configure($cfg), 1, "Component runs correctly 2nd time with same test profile");
ok(command_history_ok([
    'ip addr show',
], [
    'service network stop',
    'service network start',
    'ccm-fetch',
    'hostnamectl'
]), "network stop/start not called with same config 2nd run");

# enable hostnamectl
$executables{'/usr/bin/hostnamectl'} = 1;

# current network config has old legacy format
# new format be different, but should be keeps_state
command_history_reset();

is($cmp->Configure($cfg), 1, "Component runs correctly 3rd time with same test profile but with hostnamectl");
# if the contents here is a hardlink, it means the cleanup of the backup files failed
is(get_file_contents("/etc/sysconfig/network"), $NETWORK_HOSTNAMECTL, "Exact network config with hostnamectl");
ok(command_history_ok([
    'ip addr show',
    '/usr/bin/hostnamectl set-hostname somehost.test.domain --static',
], [
    'service network stop',
    'service network start',
    'ccm-fetch',
]), "network stop/start not called with same config with hostnamectl (KEEPS_STATE set) 3rd run");


# add ethtool options
# shouldn't trigger an ifup/ifdown cycle
command_history_reset();
$cfg = get_config_for_profile('simple_ethtool');
is($cmp->Configure($cfg), 1, "Component runs correctly w/o ethtool");
like(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-eth0"),
     qr/^ETHTOOL_OPTS='--set-channels eth0 combined 7 other 1 ; autoneg on speed 10000 wol b'$/m,
       "no ethtool opts");
# also no ethtool, as this config has no ethtool configured
ok(command_history_ok([
    '/usr/sbin/ethtool --show-channels eth0',
    '/usr/sbin/ethtool eth0',
    '/usr/sbin/ethtool --set-channels eth0 combined 7',  # no other, is already 1
    '/usr/sbin/ethtool --change eth0 speed 10000 wol b',  # no autoneg, is already on
   ], ['ifup', 'ifdown', 'restart', 'autoneg on', 'other 1']),
   "changes in ethtool do not trigger ifup/ifdown");


# check that removal ethtool_opts does not trigger ifup/ifdown
command_history_reset();
$cfg = get_config_for_profile('simple_noethtool');
is($cmp->Configure($cfg), 1, "Component runs correctly w/o ethtool");
unlike(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-eth0"),
     qr/ETHTOOL/m,
       "no ethtool opts");
# also no ethtool, as this config has no ethtool configured
ok(command_history_ok(undef, ['ethtool', 'ifup', 'ifdown', 'restart']),
   "changes in ethtool do not trigger ifup/ifdown");



# Check that realhostname is used correctly
delete $executables{'/usr/bin/hostnamectl'};
command_history_reset();
$cfg = get_config_for_profile('simple_realhostname');
is($cmp->Configure($cfg), 1, "Component runs correctly with realhostname test profile");
like(get_file_contents("/etc/sysconfig/network"),
     qr/^HOSTNAME=realhost.example.com$/m,
     "realhostname correctly used as hostname");
ok(command_history_ok(undef,[
    'hostnamectl',
]), "hostnamectl not called with realhostname");


command_history_reset();
$cfg = get_config_for_profile('simple_realhostname');
$executables{'/usr/bin/hostnamectl'} = 1;
is($cmp->Configure($cfg), 1, "Component runs correctly with realhostname test profile w hostnamectl");
unlike(get_file_contents("/etc/sysconfig/network"),
     qr/HOSTNAME=/m,
     "realhostname not used as hostname w hostnamectl");
ok(command_history_ok([
    '/usr/bin/hostnamectl set-hostname realhost.example.com --static',
]), "hostnamectl called with realhostname");


# removing broadcast that was same as computed default is ok (triggers no network restart)

set_desired_output('ipcalc --broadcast 4.3.2.1 255.255.255.0', "BROADCAST=4.3.2.255\n");

command_history_reset();
$cfg = get_config_for_profile('simple_nobroadcast');
is($cmp->Configure($cfg), 1, "Component runs correctly with nobroadcast test profile w/o broadcast");
unlike(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-eth0"),
     qr/BROADCAST=/m,
     "no broadcast set");
ok(command_history_ok([
    'ipcalc --broadcast 4.3.2.1 255.255.255.0',
], [
    'service network stop',
    'service network start',
    'ccm-fetch',
]), "network stop/start not called with same config w/o broadcast (KEEPS_STATE set) 2nd run");

done_testing();
