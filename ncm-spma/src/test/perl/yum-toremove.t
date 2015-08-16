# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<packages_to_remove> method.  This method returns the
exact set of packages to be removed, based on the lists of packages
installed and specified in the profile.

The symplistic approach of removing whatever is not listed in the
profile doesn't work for Yum: packages may have been installed due to
dependencies.

Instead, we'll have to remove only a few leaf packages, and
let C<clean_requirements_on_remove> do the rest of the work.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;
use Set::Scalar;


Readonly::Array my @LP_ORIG => @{NCM::Component::spma::yum::LEAF_PACKAGES()};
Readonly::Array my @LP => @{NCM::Component::spma::yum::_set_yum_config(\@LP_ORIG)};
Readonly my $LEAVES => join(" ", @LP);

=pod

=head2 Successful executions

=over

=item * All leaves are listed in the profile.

=cut

my $cmp = NCM::Component::spma::yum->new("spma");

my $wanted = Set::Scalar->new(qw(a;noarch b c));

set_desired_output($LEAVES, "yum plugins\na;noarch\n");

my $s = $cmp->packages_to_remove($wanted);
ok(defined($s), "Packages to remove succeeds");
isa_ok($s, "Set::Scalar::Null", "Received a correct object");
ok(!$s, "No packages to remove. Garbage lines from package-cleanup discarded");

=pod

=item * Some leaves must be removed

There are leaf packages out of the profile.

=cut

set_desired_output($LEAVES, "yum plugins\nd;noarch\n");

$s = $cmp->packages_to_remove($wanted);
ok($s, "Packages to remove succeeds and is not empty");

is($s, Set::Scalar->new("d;noarch"), "Correct set will be removed");

set_desired_output($LEAVES, "yum plugins\nb;i686\n");

$s = $cmp->packages_to_remove($wanted);
isa_ok($s, "Set::Scalar::Null", "Package wanted by name is not removed");

set_desired_output($LEAVES, "yum plugins\na;x86_64\n");
$s = $cmp->packages_to_remove($wanted);

is($s, Set::Scalar->new("a;x86_64"),
   "Package installed with wrong architecture will be removed");

=pod

=back

=head2 Failed executions

Errors must be correctly reported

=cut

set_command_status($LEAVES, 1);
$s = $cmp->packages_to_remove($wanted);
is($s, undef, "Failed execution handled properly");
is($cmp->{ERROR}, 1, "Errors in leaf detection are reported");

done_testing();
