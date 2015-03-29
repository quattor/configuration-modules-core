# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(simple);

use helper;
use NCM::Component::network;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for bridge configuration.

=cut

my $cfg = get_config_for_profile('simple');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

# generic
my $fh;

$fh = get_file($cmp->gen_backup_filename("/etc/sysconfig/network").NCM::Component::network::FAILED_SUFFIX);
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter network file written");

like($fh, qr/NETWORKING=yes/m, "Enable networking"); 
like($fh, qr/HOSTNAME=somehost.test.domain/m, "FQDN hostname"); 
like($fh, qr/GATEWAY=/m, "Set default gateway"); 

$fh = get_file($cmp->gen_backup_filename("/etc/sysconfig/network-scripts/ifcfg-eth0").NCM::Component::network::FAILED_SUFFIX);
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter network/ifcfg-eth0 file written");

like($fh, qr/ONBOOT=yes/m, "enable interface at boot time");
like($fh, qr/NM_CONTROLLED/m, "network manager option");
like($fh, qr/DEVICE=eth0/m, "set device name");
like($fh, qr/TYPE=Ethernet/m, "set type");
like($fh, qr/BOOTPROTO=static/m, "statuc config");
like($fh, qr/IPADDR=/m, "fixed IPaddr");
like($fh, qr/NETMASK=/m, "fixed netmask");
like($fh, qr/BROADCAST=/m, "fixed broadcast");


done_testing();
