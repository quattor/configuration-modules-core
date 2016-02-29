# -*- mode: cperl -*-
# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

=pod

=head1 DESCRIPTION

Tests the C<ips::reject_idrs> method.  This method adds Oracle IDRs
(packages with prefix 'idr' that contain official hotfixes) that appear
in a given list of installed packages to the hash of packages to reject.

=head1 TESTS

The test provides a dummy set of installed packages and verifies that
the IDRs are correctly added to the supplied hash.

=cut

use strict;
use warnings;
use Test::More tests => 3;
use Test::Quattor;
use NCM::Component::spma::ips;
use Set::Scalar;

my $cmp = NCM::Component::spma::ips->new("spma");

sub test_idr
{
    my ($cmp, $pkg_set, $num_idrs) = @_;

    my %reject_hash = ( marker1 => 1, marker2 => 1 );
    $cmp->reject_idrs(\%reject_hash, $pkg_set);

    if ($num_idrs == 0) {
        is(keys %reject_hash, 2,
                "Package hash size when no IDRs present");
    } else {
        is(keys %reject_hash, $num_idrs + 2,
                "Package hash size when IDRs are present");

        #
        # Verify that the items added to the reject hash
        # are indeed IDR packages
        #
        my $idr_ok = 1;
        for my $pkg (keys %reject_hash) {
            next if $pkg =~ /^marker/;
            $idr_ok = 0 if $pkg !~ /^idr[0-9]/;
        }
        ok($idr_ok, "Package hash content when IDRs are present");
    }
}

#
# Test without IDRs present
#
my @pkgs = ( "shell/bash",
             "shell/expect",
             "shell/ksh",
             "shell/ksh88",
             "shell/ksh93",
             "shell/pipe-viewer",
             "shell/tcsh",
             "shell/which",
             "shell/zsh");

my $set = Set::Scalar->new();
for my $pkg (@pkgs) {
    $set->insert($pkg);
}

test_idr($cmp, $set, 0);

#
# Test with IDRs present
#
$set->insert("idr437");
$set->insert("idr569");

test_idr($cmp, $set, 2);
