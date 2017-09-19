# -*- mode: cperl -*-
use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(simple simple_realhostname);
use Test::MockModule;

use NCM::Component::network;
my $mock = Test::MockModule->new('NCM::Component::network');
my %executables;
$mock->mock('_is_executable', sub {diag "executables $_[1] ",explain \%executables;return $executables{$_[1]};});

use Readonly;

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

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for bridge configuration.

=cut

ok($NETWORK ne $NETWORK_HOSTNAMECTL,
   "expected network config is different for case with and without hostnamectl");

# File must exist
set_file_contents("/etc/sysconfig/network", 'x' x 1000);

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
    'ip addr show',
    'service network stop',
    'service network start',
    'ccm-fetch',
], ['hostnamectl']), "network stop/start called on network config change (and no hostnamectl)");

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

done_testing();
