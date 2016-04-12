# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<spare_dependencies> method.  This method actually
chooses one of two other methods, depending on the estimated size of
the query.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;
use CAF::Object;
use Test::MockModule;
use Set::Scalar;

my $mock = Test::MockModule->new('NCM::Component::spma::yum');
my $cmp = NCM::Component::spma::yum->new("spma");

$mock->mock("spare_deps_whatreq", "whatreq");
$mock->mock("spare_deps_requires", "requires");

my $install = Set::Scalar->new();
my $rm = Set::Scalar->new();

=pod

=head2 Nothing to be done

If either set is empty, nothing is done.

=cut

is($cmp->spare_dependencies($rm, $install), 1, "Nothing is done on empty sets");
$rm->insert("a");
is($cmp->spare_dependencies($rm, $install), 1, "Nothing is done on empty install");

=pod

=head2 The correct callee is chosen

In most circumstances the C<requires> path is used.  Only in very
large installations with almost nothing to remove we resort to the
C<whatreq> path.

=cut

$install->insert(qw(a b c d));
is($cmp->spare_dependencies($rm, $install), "requires",
   "Correct method is called when install part is small");

$install->insert(0..2000);
is($cmp->spare_dependencies($rm, $install), "whatreq",
   "The whatrequires method is called only when the win is obvious");

done_testing();
