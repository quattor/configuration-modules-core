# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<spare_dependencies> method.  This method removes
packages to be deleted if they are listed in the output of a "magic"
invocation to C<repoquery>.

=head1 TESTS

=head2 Sucessful executions

The method must succeed, because the command invocation does.  We have
three cases here:

=over

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use NCM::Component::spma;
use Test::Quattor;
use Set::Scalar;

Readonly my $REPO_CMD => join(" ", NCM::Component::spma::REPO_DEPS,
			      "pkg;noarch");

set_desired_output($REPO_CMD, "dep;noarch");
set_desired_err($REPO_CMD, "");

my $cmp = NCM::Component::spma->new("spma");

my ($to_install, $to_rm);

$to_install = Set::Scalar->new("pkg;noarch");

=pod

=item * There is nothing to remove.

The command is not even called

=cut

is($cmp->spare_dependencies($to_rm, $to_install), 1,
   "Execution succeeds when there is nothing to remove");
my $cmd = get_command($REPO_CMD);
ok(!$cmd, "When nothing to remove the command is not even called");

=pod

=item * A package to be removed is depended upon by something that
must be installed.

The package won't be removed, then.

=cut

$to_rm = Set::Scalar->new("dep;noarch");

is($cmp->spare_dependencies($to_rm, $to_install), 1,
   "Basic execution succeeded");
ok(!@$to_rm, "Dependency successfully removed from the list of packages to remove");

=pod

=item * The packages to be installed don't depend on any packages to
be removed

The package will still be listed for removal.

=back

=cut

$to_rm = Set::Scalar->new("nodep;noarch");

is($cmp->spare_dependencies($to_rm, $to_install), 1,
   "Execution with no overlapping dependencies succeeds");
is(scalar(@$to_rm), 1,
   "Packages to remove are preserved if no dependencies overlap");

=pod

=head2  Execution failures

If repoquery fails or report an error, it must be propagated to its caller.

=cut

set_desired_err($REPO_CMD, "Error: this is an error");
is($cmp->spare_dependencies($to_rm, $to_install), 0,
   "Errors in repoquery are reported");

set_command_status($REPO_CMD, 1);
is($cmp->spare_dependencies($to_rm, $to_install), 0,
   "Failures in repoquery are detected and propagated");


done_testing();
