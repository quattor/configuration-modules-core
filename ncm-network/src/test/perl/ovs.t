# -*- mode: cperl -*-
use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(ovs);
use NCM::Component::network;

use Readonly;

Readonly my $BR => <<EOF;
ONBOOT=yes
NM_CONTROLLED='no'
DEVICE=br100
TYPE=OVSBridge
DEVICETYPE='ovs'
BOOTPROTO=static
IPADDR=4.3.2.1
NETMASK=255.255.255.0
BROADCAST=4.3.2.255
EOF

Readonly my $ETH0 => <<EOF;
ONBOOT=yes
NM_CONTROLLED='no'
DEVICE=eth0
TYPE=OVSPort
DEVICETYPE='ovs'
OVS_BRIDGE='br100'
BOOTPROTO=none
EOF


=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for OVS configuration.

=cut

# File must exist
set_file_contents("/etc/sysconfig/network", '');

my $cfg = get_config_for_profile('ovs');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $bfh = get_file($cmp->testcfg_filename("/etc/sysconfig/network-scripts/ifcfg-br100"));
ok(!defined($bfh), "testcfg network/ifcfg-br100 cleaned up");

is(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-br100"), $BR, "exact br config");

my $ifh = get_file($cmp->testcfg_filename("/etc/sysconfig/network-scripts/ifcfg-eth0"));
ok(!defined($ifh), "testcfg network/ifcfg-eth0 cleaned up");

is(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-eth0"), $ETH0, "exact eth0 config");

done_testing();
