# -*- mode: cperl -*-
# ${license-info}
# Author: ${spma.ips.author} <${spma.ips.email}>
# ${build-info}

=pod

=head1 DESCRIPTION

Tests the C<ips::ips_to_remove> method.  This method returns a list of
packages to remove by subtracting the list of packages that would appear
in a fresh install from those already installed.

=head1 TESTS

The test provides a representative package hashes to the method and
verifies the output.

=cut

use strict;
use warnings;
use Test::More tests => 2;
use Test::Quattor;
use NCM::Component::spma::ips;
use Readonly;
use Set::Scalar;

Readonly my @fresh_pkgs => ( "runtime/java",
                             "runtime/java/jre-6",
                             "runtime/java/jre-7",
                             "runtime/lua",
                             "runtime/perl-512",
                             "runtime/python-26",
                             "runtime/tcl-8"
                           );
Readonly my @extra_pkgs => ( "support/explorer",
                             "developer/gcc-45",
                             "developer/assembler",
                             "idr437"
                           );

my $cmp = NCM::Component::spma::ips->new("spma");

my $fresh_set = Set::Scalar->new(@fresh_pkgs);
my $installed_set = Set::Scalar->new(@fresh_pkgs, @extra_pkgs);
my $rm_list = $cmp->ips_to_remove($fresh_set, $installed_set);

cmp_ok(@$rm_list, 'le', @extra_pkgs, "Check number of packages to remove");

my $extra_set = Set::Scalar->new(@extra_pkgs);
my $rm_ok = 1;
for my $pkg (@$rm_list) {
    $rm_ok = 0 unless $pkg =~ /^idr[0-9]/ or $extra_set->has($pkg);
}
ok($rm_ok, "List of packages to remove are correct");
