# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<spare_deps_requires> method.  This method shall call
repoquery --requires with the list of packages to be installed.

=head1 TESTS

=head2 Successful executions

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use NCM::Component::spma;
use CAF::Object;
use Test::Quattor;
use Set::Scalar;

my $install = Set::Scalar->new('pkg;noarch');
my $rm = Set::Scalar->new('dep;noarch', 'nodep;noarch');
my $cmp = NCM::Component::spma->new('spma');

Readonly my $CMD => join(" ", NCM::Component::spma::REPO_DEPS, 'pkg.noarch');

set_desired_output($CMD, 'dep;noarch');
set_desired_err($CMD, '');

ok($cmp->spare_deps_requires($rm, $install), "Normal execution succeeds");
ok($rm->has('nodep;noarch'), "Non-dependency is kept for removal");
ok(!$rm->has('dep;noarch'), "Dependency is removed from rm");

=pod

=head2 Error handling

The error is reported and there are no side effects.

=cut

set_desired_err($CMD, 'Error: fubarr!');
$rm->insert('dep;noarch');

ok(!$cmp->spare_deps_requires($rm, $install), "Error is detected");
ok($rm->has('dep;noarch'), "The remove list is not touched upon errors");

done_testing();
