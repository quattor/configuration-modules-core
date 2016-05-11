# -*- mode: cperl -*-
# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

=pod

=head1 DESCRIPTION

Tests the C<ips::pkg_keys> method.  This method returns a reference to an
array of pkg@ver format strings when given a hash where pkg is the key and ver
is the value.

=head1 TESTS

The test provides a representative package hash to the method and
verifies the output.

=cut

use strict;
use warnings;
use Test::More tests => 4;
use Test::Quattor;
use NCM::Component::spma::ips;
use Readonly;

sub test_pkgkeys {
    my ($cmp, $pkg_hash, $mode) = @_;

    my $pkg_keys = $cmp->pkg_keys($pkg_hash);
    my $mode_desc = ($mode == 1 ? "with versions" : "without version");

    is(@$pkg_keys, keys %$pkg_hash,
            "Correct number of package keys returned from hash $mode_desc");

    my $i = 0;
    my $array_ok = 1;
    while (my ($pkg, $ver) = each %$pkg_hash) {
        $array_ok = 0 if $mode == 1 and $pkg_keys->[$i] ne "$pkg\@$ver";
        $array_ok = 0 if $mode != 1 and $pkg_keys->[$i] ne "$pkg";
        $i++;
    }

    ok($array_ok, "Verify package keys from hash " .
                  ($mode == 1 ? "with versions" : "without version"));
}

my $cmp = NCM::Component::spma::ips->new("spma");

#
# Test with both package names and versions
#
Readonly my %ver_hash => (
                 "p1" => "1.0",
                 "pkg:/p2" => "1.0,5.11-1.2.3",
                 "pkg://pub/p3" => "1.0,5.11-1.2.3:20131212T112401Z"
               );

test_pkgkeys($cmp, \%ver_hash, 1);

#
# Test package names only
#
Readonly my %no_ver_hash => (
                 "p1" => "",
                 "pkg:/p2" => "",
                 "pkg://pub/p3" => ""
               );

test_pkgkeys($cmp, \%no_ver_hash, 0);
