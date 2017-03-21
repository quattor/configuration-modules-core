# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(ovs);
use helper;
use NCM::Component::network;

use Readonly;

Readonly my $BR => <<EOF;
ONBOOT=yes
NM_CONTROLLED='no'
DEVICE=br-ex
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
OVS_BRIDGE='br-ex'
BOOTPROTO=none
EOF


=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for OVS configuration.

=cut

my $cfg = get_config_for_profile('ovs');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $bfh = get_file($cmp->gen_backup_filename("/etc/sysconfig/network-scripts/ifcfg-br-ex").$NCM::Component::network::FAILED_SUFFIX);
isa_ok($bfh,"CAF::FileWriter","This is a CAF::FileWriter network/ifcfg-br-ex file written");

like($bfh, qr/^TYPE=OVSBridge$/m, "set type for the OVS bridge");
like($bfh, qr/^DEVICETYPE='ovs'$/m, "set device_type as ovs");
like($bfh, qr/^BOOTPROTO=static$/m, "set bootproto for the OVS bridge");

unlike($bfh, qr/IPV6/, "No IPv6 config details");

is("$bfh", $BR, "exact br config");

my $ifh = get_file($cmp->gen_backup_filename("/etc/sysconfig/network-scripts/ifcfg-eth0").$NCM::Component::network::FAILED_SUFFIX);
isa_ok($ifh,"CAF::FileWriter","This is a CAF::FileWriter network/ifcfg-eth0 file written");

like($ifh, qr/^TYPE=OVSPort$/m, "set type for the OVS port");
like($ifh, qr/^DEVICETYPE='ovs'$/m, "set device_type as ovs");
like($ifh, qr/^OVS_BRIDGE='br-ex'$/m, "set bridge for the OVS port");
like($ifh, qr/^BOOTPROTO=none$/m, "set bootproto for the OVS port");

unlike($ifh, qr/IPV6/, "No IPv6 config details");

is("$ifh", $ETH0, "exact eth0 config");

done_testing();
