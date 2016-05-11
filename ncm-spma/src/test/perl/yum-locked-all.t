# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<locked_all_packages> method.

Verifies that all the packages we wanted to lock down are actually locked down.

=head1 TESTS

=cut

use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;
use Set::Scalar;

my $cmp = NCM::Component::spma::yum->new("spma");

my $wanted_locked = Set::Scalar->new(qw(a b c));
my $locked = join("\n", qw(0:a 0:b 0:c));

is($cmp->locked_all_packages($wanted_locked, $locked), 1,
   "Detected when all packages are locked");

$wanted_locked = Set::Scalar->new(qw(a b c d));

is($cmp->locked_all_packages($wanted_locked, $locked), 0,
   "Detected when a package is not versionlocked correctly");

done_testing();
