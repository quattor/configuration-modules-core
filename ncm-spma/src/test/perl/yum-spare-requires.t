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
use Test::Quattor;
use NCM::Component::spma::yum;
use CAF::Object;
use Set::Scalar;

my $install = Set::Scalar->new('pkg;noarch');
my $rm = Set::Scalar->new('dep;noarch', 'nodep;noarch');
my $cmp = NCM::Component::spma::yum->new('spma');

Readonly::Array my @DEPS_ORIG => NCM::Component::spma::yum::REPO_DEPS();
Readonly::Array my @DEPS => @{NCM::Component::spma::yum::_set_yum_config(\@DEPS_ORIG)};
Readonly my $CMD => join(" ", @DEPS, 'pkg.noarch');

ok(grep {$_ eq '-C'} @DEPS, 'repoqeury command has cache enabled');

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
