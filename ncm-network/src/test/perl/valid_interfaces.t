use strict;
use warnings;
use Test::Quattor;
use Test::More;

use NCM::Component::network;

my $cmp = NCM::Component::network->new('network');

=head1 Test valid interfaces

=cut

my $basedir = "/etc/sysconfig/network-scripts/";
my @valid_ifs = qw(eth0 seth1 em2 em2_2
    bond3 br4 ovirtmgmt5
    vlan6 vxlan6 usb7 ib8 p9p10
    eno11 eno11d123 eno11np1234 ens12 ens13f14 ens15d16 ens17f18d19
    enp22s23 enp24s25f26 enp27s28d29 enp30s31f32d33 ens34f35np36
    enxAABBCCDDEEFF);

foreach my $valid (@valid_ifs) {
    foreach my $type (qw(ifcfg route route6)) {
        is_deeply(
            $cmp->is_valid_interface("$basedir/$type-$valid"), [$valid, $valid],
            "valid interface $valid from $type"
        );
        is_deeply(
            $cmp->is_valid_interface("$basedir/$type-$valid.123"), [$valid, "$valid.123"],
            "valid interface $valid from $type with vlan"
        );
        is_deeply(
            $cmp->is_valid_interface("$basedir/$type-$valid:alias"), [$valid, "$valid:alias"],
            "valid interface $valid from $type with alias"
        );
        is_deeply(
            $cmp->is_valid_interface("$basedir/$type-$valid.456:myalias"), [$valid, "$valid.456:myalias"],
            "valid interface $valid from $type with vlan and alias"
        );
        is_deeply(
            $cmp->is_valid_interface("$basedir/$type-${valid}_whatever.456:myalias"),
            [$valid =~ m/^(.*)_\d+$/ ? $1 : $valid, "${valid}_whatever.456:myalias"],
            "valid interface $valid from $type with suffix, vlan and alias"
        );
    };
};

my @invalid_ifs = (
    'contains/slash',
    'too-many-characters',
    'multiple::colons',
    'space in_name',
);
foreach my $invalid (@invalid_ifs) {
    ok(!defined($cmp->is_valid_interface("$basedir/ifcfg-$invalid")), "invalid interface $invalid");
};

done_testing();
