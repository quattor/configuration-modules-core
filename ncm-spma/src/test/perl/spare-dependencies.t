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
use NCM::Component::spma;
use CAF::Object;
use Test::MockModule;
use Set::Scalar;

my $mock = Test::MockModule->new('NCM::Component::spma');
my $cmp = NCM::Component::spma->new("spma");

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

The methods to be called are chosen based on the expected size of the
transaction.

=cut

$install->insert(qw(a b));
is($cmp->spare_dependencies($rm, $install), "whatreq",
   "Correct method is called when whatreq path is faster");
$rm->insert(qw(d e f g));
is($cmp->spare_dependencies($rm, $install), "requires",
   "Correct method is called when requires path is faster");

done_testing();
