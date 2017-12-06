use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(ipv6);

use NCM::Component::network;
use Test::MockModule;
my $mock = Test::MockModule->new('NCM::Component::network');
my %executables;
$mock->mock('_is_executable', sub {diag "executables $_[1] ",explain \%executables;return $executables{$_[1]};});

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
DEFROUTE=yes
IPV6ADDR=2001:678:123:e012::45/64
IPV6ADDR_SECONDARIES='2001:678:123:e012::46/64 2001:678:123:e012::47/64'
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6INIT=yes
EOF

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for ipv6 configuration.

=cut

# File must exist
set_file_contents("/etc/sysconfig/network", '');

my $cfg = get_config_for_profile('ipv6');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

# generic
my $fh;

$fh = get_file($cmp->testcfg_filename("/etc/sysconfig/network"));
ok(! defined($fh),"testcfg network cleaned up");

is(get_file_contents("/etc/sysconfig/network"), $NETWORK, "exact network config");

$fh = get_file($cmp->testcfg_filename("/etc/sysconfig/network-scripts/ifcfg-eth0"));
ok(! defined($fh), "testcfg network/ifcfg-eth0 cleaned up");

is(get_file_contents("/etc/sysconfig/network-scripts/ifcfg-eth0"), $ETH0, "exact eth0 config");

done_testing();
