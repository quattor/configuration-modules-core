use strict;
use warnings;
use Test::More;
use Test::Quattor qw(ipv6);

use helper;
use NCM::Component::network;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for ipv6 configuration.

=cut

my $cfg = get_config_for_profile('ipv6');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

# generic
my $fh;

$fh = get_file($cmp->gen_backup_filename("/etc/sysconfig/network").NCM::Component::network::FAILED_SUFFIX);
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter network file written");

like($fh, qr/^NETWORKING=yes$/m, "Enable networking"); 
like($fh, qr/^HOSTNAME=somehost.test.domain$/m, "FQDN hostname"); 
like($fh, qr/^GATEWAY=/m, "Set default gateway"); 

like($fh, qr/^NETWORKING_IPV6=yes$/m, "Enable IPv6 networking");
like($fh, qr/^IPV6_DEFAULTDEV=eth0$/m, "Set IPv6 defaultdev via ipv6/gatewaydev");

$fh = get_file($cmp->gen_backup_filename("/etc/sysconfig/network-scripts/ifcfg-eth0").NCM::Component::network::FAILED_SUFFIX);
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter network/ifcfg-eth0 file written");

like($fh, qr/^IPV6ADDR=2001:678:123:e012::45\/64$/m, "set ipv6 addr");
like($fh, qr/^IPV6ADDR_SECONDARIES='2001:678:123:e012::46\/64 2001:678:123:e012::47\/64'$/m, "set ipv6 addr");
like($fh, qr/^IPV6_AUTOCONF=no$/m, "IPV6 autoconf disabled");
like($fh, qr/^IPV6INIT=yes$/m, "IPv6 INIT (implicitly) enabled");

done_testing();
