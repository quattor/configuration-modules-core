# -*- mode: cperl -*-
use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(simple simple_realhostname);

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

# File must exist
set_file_contents("/etc/sysconfig/network", '');

my $cfg = get_config_for_profile('simple');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

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
    '/sbin/ifconfig -a',
    'service network stop',
    'service network start',
    'ccm-fetch',
]), "network stop/start called on network config change");

command_history_reset();

is($cmp->Configure($cfg), 1, "Component runs correctly 2nd time with same test profile");
ok(command_history_ok([
    '/sbin/ifconfig -a',
], [
    'service network stop',
    'service network start',
    'ccm-fetch',
]), "network stop/start not called with same config");


# Check that realhostname is used correctly
$cfg = get_config_for_profile('simple_realhostname');
is($cmp->Configure($cfg), 1, "Component runs correctly with realhostname test profile");
like(get_file_contents("/etc/sysconfig/network"),
     qr/^HOSTNAME=realhost.example.com$/m,
     "realhostname correctly used as hostname");

done_testing();
