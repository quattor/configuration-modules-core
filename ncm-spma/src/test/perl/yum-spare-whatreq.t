# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<spare_deps_whatreq> method.  This method shall call
repoquery --whatrequires with the list of packages to be installed.

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

my $rm = Set::Scalar->new('dep;noarch', 'nodep;noarch');
my $install = Set::Scalar->new('pkg;noarch');
my $cmp = NCM::Component::spma::yum->new('spma');

Readonly::Array my @WHATREQS_ORIG => NCM::Component::spma::yum::REPO_WHATREQS();
Readonly::Array my @WHATREQS => @{NCM::Component::spma::yum::_set_yum_config(\@WHATREQS_ORIG)};
Readonly::Array my @CMD => (
    join(" ", @WHATREQS, 'dep.noarch'),
    join(" ", @WHATREQS, 'nodep.noarch'));

ok(grep {$_ eq '-C'} @WHATREQS, 'repoqeury command has cache enabled');

set_desired_output($CMD[0], 'pkg;noarch');
set_desired_err($CMD[0], '');
set_desired_output($CMD[1], 'foo;noarch');
set_desired_err($CMD[1], '');

ok($cmp->spare_deps_whatreq($rm, $install), "Normal execution succeeds");
ok($rm->has('nodep;noarch'), "Non-dependended is kept for removal");
ok(!$rm->has('dep;noarch'), "Dependency is removed from rm");

=pod

=head2 Error handling

The list of packages may be modified, but the error must be reported correctly.

=cut

set_desired_err($CMD[0], 'Error: fubarr!');
$rm->insert('dep;noarch');

ok(!$cmp->spare_deps_whatreq($rm, $install), "Error is detected");

done_testing();
