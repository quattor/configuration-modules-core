# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(simple simple_realhostname);

use helper;
use NCM::Component::network;

use Readonly;

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

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for bridge configuration.

=cut

my $cfg = get_config_for_profile('simple');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

# generic
my $fh;

$fh = get_file($cmp->testcfg_filename("/etc/sysconfig/network"));
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter network file written");

like($fh, qr/^NETWORKING=yes$/m, "Enable networking"); 
like($fh, qr/^HOSTNAME=somehost.test.domain$/m, "FQDN hostname"); 
like($fh, qr/^GATEWAY=/m, "Set default gateway"); 

unlike($fh, qr/IPV6/, "No IPv6 config details");

is("$fh", $NETWORK, "Exact network config");


$fh = get_file($cmp->testcfg_filename("/etc/sysconfig/network-scripts/ifcfg-eth0"));
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter network/ifcfg-eth0 file written");

like($fh, qr/^ONBOOT=yes$/m, "enable interface at boot time");
like($fh, qr/^NM_CONTROLLED=/m, "network manager option");
like($fh, qr/^DEVICE=eth0$/m, "set device name");
like($fh, qr/^TYPE=Ethernet$/m, "set type");
like($fh, qr/^BOOTPROTO=static$/m, "statuc config");
like($fh, qr/^IPADDR=/m, "fixed IPaddr");
like($fh, qr/^NETMASK=/m, "fixed netmask");
like($fh, qr/^BROADCAST=/m, "fixed broadcast");

unlike($fh, qr/IPV6/, "No IPv6 config details");

is("$fh", $ETH0, "Exact network config");


# Check that realhostname is used correctly
$cfg = get_config_for_profile('simple_realhostname');
is($cmp->Configure($cfg), 1, "Component runs correctly with realhostname test profile");
$fh = get_file($cmp->testcfg_filename("/etc/sysconfig/network"));

like($fh, qr/^HOSTNAME=realhost.example.com$/m, "realhostname correctly used as hostname");

done_testing();
