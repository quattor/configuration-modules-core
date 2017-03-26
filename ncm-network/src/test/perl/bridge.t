# -*- mode: cperl -*-
use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(bridge);
use NCM::Component::network;

use Readonly;

Readonly my $BR0 => <<EOF;
ONBOOT=yes
NM_CONTROLLED='no'
DEVICE=br0
TYPE=Ethernet
BOOTPROTO=static
IPADDR=4.3.2.1
NETMASK=255.255.255.0
BROADCAST=4.3.2.255
STP=on
DELAY=5
BRIDGING_OPTS='hairpin_mode=5'
EOF

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for bridge configuration.

=cut

# File must exist
set_file_contents("/etc/sysconfig/network", '');

my $cfg = get_config_for_profile('bridge');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $fh = get_file($cmp->testcfg_filename("/etc/sysconfig/network-scripts/ifcfg-br0"));
ok(! defined($fh), "testcfg network/ifcfg-br0 was cleaned up");

is(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-br0"), $BR0, "exact bridge config");

done_testing();
