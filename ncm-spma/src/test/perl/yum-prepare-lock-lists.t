# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<prepare_lock_lists> method.

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

my $pkglist = {
          "nc"=> {},
          "ncm_2daccounts"=> {
              "_313_2e5_2e0_2d1"=> {
                  "arch"=> {
                      "noarch"=> ""
                     },
              },
          },
          "sssd_2a"=> {
              "_31_2e9_2e2_2d82_2e7_2eel6_5f4"=> {
                  "arch"=> {
                      "x86_64"=> ""
                     }
                 }
             },

};

my ($locked, $toquery) = $cmp->prepare_lock_lists($pkglist);

is(scalar(@$toquery), 2, "Correct number of elements locked");
is(scalar(@$locked), scalar(@$toquery),
   "Set and list contain the same number of elements");
ok($locked->has("sssd-1.9.2-82.7.el6_4.x86_64"),
   "Starred element present in locked list");
ok(grep($_ eq "sssd*-1.9.2-82.7.el6_4.x86_64", @$toquery),
   "Starred element to be passed to repoquery");

done_testing();
