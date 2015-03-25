# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(ovs);
use NCM::Component::network;


$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for OVS configuration.

=cut

my $cfg = get_config_for_profile('ovs');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $bfh = get_file($cmp->gen_backup_filename("/etc/sysconfig/network-scripts/ifcfg-br-ex").NCM::Component::network::FAILED_SUFFIX);
isa_ok($bfh,"CAF::FileWriter","This is a CAF::FileWriter network/ifcfg-br-ex file written");

like($bfh, qr/TYPE=OVSBridge/m, "set type for the OVS bridge");
like($bfh, qr/DEVICE_TYPE='ovs'/m, "set device_type as ovs");
like($bfh, qr/BOOTPROTO=static/m, "set bootproto for the OVS bridge");

my $ifh = get_file($cmp->gen_backup_filename("/etc/sysconfig/network-scripts/ifcfg-eth0").NCM::Component::network::FAILED_SUFFIX);
isa_ok($ifh,"CAF::FileWriter","This is a CAF::FileWriter network/ifcfg-eth0 file written");

like($ifh, qr/TYPE=OVSPort/m, "set type for the OVS port");
like($ifh, qr/DEVICETYPE='ovs'/m, "set device_type as ovs");
like($ifh, qr/OVS_BRIDGE='br-ex'/m, "set bridge for the OVS port");
like($ifh, qr/BOOTPROTO=none/m, "set bootproto for the OVS port");

done_testing();
