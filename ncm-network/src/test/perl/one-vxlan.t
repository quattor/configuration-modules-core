use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(one-vxlan);
use NCM::Component::network;

use Readonly;

Readonly my $BR => <<EOF;
ONBOOT=yes
NM_CONTROLLED='no'
DEVICE=vxlan1034
TYPE=Bridge
BOOTPROTO=static
EOF

Readonly my $VXLAN => <<EOF;
ONBOOT=yes
NM_CONTROLLED='no'
DEVICE=ib0.1034
TYPE=Ethernet
BRIDGE='vxlan1034'
BOOTPROTO=static
PHYSDEV=ib0
VXLAN=yes
VNI=1034
GROUP_IPADDR=239.0.4.10
EOF

Readonly my $VXLANREMOTE => <<EOF;
ONBOOT=yes
NM_CONTROLLED='no'
DEVICE=vxlan123
TYPE=Ethernet
BOOTPROTO=static
PHYSDEV=ib0
VXLAN=yes
VNI=123
REMOTE_IPADDR=9.8.7.5
PEER_OUTER_IPADDR=9.8.7.5
LOCAL_IPADDR=9.8.7.6
MY_OUTER_IPADDR=9.8.7.6
DSTPORT=1234
GBP=yes
EOF


=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for VXLAN plugin with ONE vxlan config.

=cut

# File must exist
set_file_contents("/etc/sysconfig/network", '');

my $cfg = get_config_for_profile('one-vxlan');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

is(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-br1034"), $BR, "exact br config");
is(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-vxlan1034"), $VXLAN, "exact VXLAN config");
is(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-vxlan123"), $VXLANREMOTE, "exact VXLAN remote config");

done_testing();
