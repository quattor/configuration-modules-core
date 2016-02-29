# -*- mode: cperl -*-
# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

=pod

=head1 DESCRIPTION

Tests the C<ips::frozen_ips> method.  This method returns a hash of
frozen IPS packages.

=head1 TESTS

The test sets up dummy output for the PKG_LIST_V command and
verifies the output of the method.

=cut

use strict;
use warnings;
use Test::More tests => 4;
use Test::Quattor;
use NCM::Component::spma::ips;
use Readonly;

Readonly my $PKG_LIST_V => join(" ",
                                @{NCM::Component::spma::ips::PKG_LIST_V()});
Readonly my $pkg_list_subset =>
'pkg://solaris/developer/gnu-binutils@2.21.1,5.11-0.175.1.0.0.24.0:20120904T171639Z i--
pkg://solaris/library/gmp@4.3.2,5.11-0.175.1.0.0.24.0:20120904T172418Z       i--
pkg://solaris/library/mpc@0.9,5.11-0.175.1.0.0.24.0:20120904T172557Z         i--
pkg://solaris/library/mpfr@2.4.2,5.11-0.175.1.0.0.24.0:20120904T172558Z      i--
pkg://solaris/shell/ksh93@93.21.0.20110208,5.11-0.175.1.0.0.24.0:20120904T174231Z i--
pkg://solaris/system/header@0.5.11,5.11-0.175.1.0.0.24.2:20120919T184855Z    i--
pkg://solaris/system/library@0.5.11,5.11-0.175.1.0.0.24.2:20120919T185104Z   i--
pkg://solaris/system/library/gcc-45-runtime@4.5.2,5.11-0.175.1.0.0.24.0:20120904T174309Z i--
pkg://solaris/system/linker@0.5.11,5.11-0.175.1.0.0.24.2:20120919T185204Z    i--';
Readonly my $pkg_list_frozen =>
'pkg://solaris/developer/gcc-45@4.5.2,5.11-0.175.1.0.0.24.0:20120904T171315Z  if-
pkg://Symantec/VRTSvcs@6.0.300.1,5.11:20130326T073138Z                       if-';

sub test_frozen
{
    my ($cmp, $pkgs, $pkgs_frozen) = @_;

    my ($pkg_out, $num_frozen);
    if (defined($pkgs_frozen)) {
        $pkg_out = "$pkgs\n$pkgs_frozen";
        $num_frozen = scalar(my @lst = split /\n/, $pkgs_frozen);
    } else {
        $pkg_out = $pkgs;
        $num_frozen = 0;
    }
    set_desired_output($PKG_LIST_V, $pkg_out);

    my $frozen_hash = $cmp->frozen_ips();
    ok(defined(get_command($PKG_LIST_V)), "pkg list command was invoked");

    is(keys %$frozen_hash, $num_frozen,
                "Frozen packages hash has correct number of elements");
}

my $cmp = NCM::Component::spma::ips->new("spma");

#
# Test when there are no frozen packages
#
test_frozen($cmp, $pkg_list_subset);

#
# Test when there are frozen packages
#
test_frozen($cmp, $pkg_list_subset, $pkg_list_frozen);
