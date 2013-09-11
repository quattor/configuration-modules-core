# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(bridge);
use NCM::Component::network;


$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component for bridge configuration.

=cut

my $cfg = get_config_for_profile('bridge');
my $cmp = NCM::Component::network->new('network');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my $fh = get_file($cmp->gen_backup_filename("/etc/sysconfig/network-scripts/ifcfg-br0").NCM::Component::network::FAILED_SUFFIX);
isa_ok($fh,"CAF::FileWriter","This is a CAF::FileWriter network/ifcfg-br0 file written");

like($fh, qr/STP=on/m, "enable STP");
like($fh, qr/DELAY=\d+/m, "set bridge delay");
like($fh, qr/BRIDGING_OPTS='.*hairpin_mode=5.*'/m, "set bridge_opts");

done_testing();
