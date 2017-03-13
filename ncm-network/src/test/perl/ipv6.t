use strict;
use warnings;
use Test::More;
use Test::Quattor qw(ipv6);

use helper;
use NCM::Component::network;

use Readonly;

Readonly my $NETWORK => <<EOF;
NETWORKING=yes
HOSTNAME=somehost.test.domain
GATEWAY=4.3.2.254
IPV6_DEFAULTGW=2001:678:123:e012::2
IPV6_DEFAULTDEV=eth0
NETWORKING_IPV6=yes
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
IPV6ADDR=2001:678:123:e012::45/64
IPV6ADDR_SECONDARIES='2001:678:123:e012::46/64 2001:678:123:e012::47/64'
IPV6_AUTOCONF=no
IPV6INIT=yes
EOF

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for ipv6 configuration.

=cut

my $cfg = get_config_for_profile('ipv6');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

# generic
my $fh;

$fh = get_file($cmp->testcfg_filename("/etc/sysconfig/network"));
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter network file written");

like($fh, qr/^NETWORKING=yes$/m, "Enable networking"); 
like($fh, qr/^HOSTNAME=somehost.test.domain$/m, "FQDN hostname"); 
like($fh, qr/^GATEWAY=/m, "Set default gateway"); 

like($fh, qr/^NETWORKING_IPV6=yes$/m, "Enable IPv6 networking");
like($fh, qr/^IPV6_DEFAULTDEV=eth0$/m, "Set IPv6 defaultdev via ipv6/gatewaydev");

is("$fh", $NETWORK, "exact network config");

$fh = get_file($cmp->testcfg_filename("/etc/sysconfig/network-scripts/ifcfg-eth0"));
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter network/ifcfg-eth0 file written");

like($fh, qr/^IPV6ADDR=2001:678:123:e012::45\/64$/m, "set ipv6 addr");
like($fh, qr/^IPV6ADDR_SECONDARIES='2001:678:123:e012::46\/64 2001:678:123:e012::47\/64'$/m, "set ipv6 addr");
like($fh, qr/^IPV6_AUTOCONF=no$/m, "IPV6 autoconf disabled");
like($fh, qr/^IPV6INIT=yes$/m, "IPv6 INIT (implicitly) enabled");

is("$fh", $ETH0, "exact eth0 config");

done_testing();
