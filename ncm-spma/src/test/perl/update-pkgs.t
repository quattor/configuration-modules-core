# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<update_pkgs> method. This method coordinates all the
upgrade process: checks what packages are available, decides which
packages must be removed and installed, and performs the update in a
single transaction.

=head1 TESTS

This method just does nothing on its own. It just calls other methods
so all testing is ensuring that the callees receive the correct
arguments.

The tests are just:

=head2 Basic test

Ensure that an ordinary execution works. Two cases here:

=over

=item * When C<userpkgs> is true, we don't try to remove packages.

=cut

use strict;
use warnings;
use Readonly;


use Test::Quattor;
use Test::More;
use NCM::Component::spma::yum;
use Test::MockModule;
use File::Path qw(mkpath rmtree);
use LC::File;

use Set::Scalar;

# Actually, this update_pkgs just coordinates a set of other methods,
# which are not relevant for this testing script. For that purpose, we
# override them.
#
# All our backup methods will return 1 unless specified by the test
# script.

my $mock = Test::MockModule->new('NCM::Component::spma::yum');


foreach my $method (qw(installed_pkgs wanted_pkgs apply_transaction versionlock
		       expire_yum_caches complete_transaction distrosync
		       spare_dependencies expand_groups packages_to_remove
                       solve_transaction)) {
    $mock->mock($method,  sub {
		    my $self = shift;
		    $self->{uc($method)}->{args} = \@_;
		    $self->{uc($method)}->{called}++;
		    return exists($self->{uc($method)}->{return}) ?
		      $self->{uc($method)}->{return} : 1;
		});
}

$mock->mock('schedule', sub {
		my ($self, $op, $args) = @_;
		$self->{SCHEDULE}->{$op}->{args} = $args;
		$self->{SCHEDULE}->{$op}->{called}++;
		if (exists($self->{SCHEDULE}->{$op}->{return})) {
		    return $self->{SCHEDULE}->{$op}->{return};
		}
		return "$op\n";
	    });

sub clear_mock_counters
{
    my $cmp = shift;
    foreach my $m (qw(apply_transaction solve_transaction schedule versionlock
		      expire_yum_caches complete_transaction distrosync
                      expand_groups wanted_pkgs installed_pkgs
                      packages_to_remove)) {
	$cmp->{uc($m)}->{called} = 0;
	if ($m !~ m{pkgs$}) {
	    $cmp->{uc($m)}->{return} = 1;
	}
    }

    $cmp->{SCHEDULE}->{install}->{called} = 0;
    $cmp->{SCHEDULE}->{remove}->{called} = 0;
    $cmp->{SCHEDULE}->{install}->{return} = "install foo";

}

my $cmp = NCM::Component::spma::yum->new("spma");

my $pkgs = {};
$cmp->{WANTED_PKGS}->{return} = Set::Scalar->new(qw(a b c));
$cmp->{INSTALLED_PKGS}->{return} = Set::Scalar->new(qw(b c d));
$cmp->{PACKAGES_TO_REMOVE}->{return} = Set::Scalar->new(qw(a));
$cmp->{EXPAND_GROUPS}->{return} = Set::Scalar->new();
$cmp->{SOLVE_TRANSACTION}->{return} = "solve\n";
$cmp->{APPLY_TRANSACTION}->{return} = "apply";

is($cmp->update_pkgs("pkgs", "groups", "run", "allow"), 1,
   "Basic invocation returns success");
is($cmp->{INSTALLED_PKGS}->{called}, 1, "Installed packages called");
is(scalar(@{$cmp->{INSTALLED_PKGS}->{args}}), 0,
   "Installed packages called with no arguments");
is($cmp->{WANTED_PKGS}->{args}->[0], "pkgs",
   "wanted_pkgs receives the expected arguments");
ok($cmp->{SOLVE_TRANSACTION}->{called}, "Transaction solving is called");
is($cmp->{SOLVE_TRANSACTION}->{args}->[0], "run",
   "Transaction solving receives the correct flag");
ok($cmp->{COMPLETE_TRANSACTION}->{called}, "Transaction completion is called");
is($cmp->{SCHEDULE}->{install}->{called}, 1, "Installation of packages is called");
ok(!$cmp->{SCHEDULE}->{remove}->{called},
   "With allow userpkgs, no removal is scheduled");

ok(!$cmp->{PACKAGES_TO_REMOVE}->{called}, "No packages to be removed with userpkgs");
ok($cmp->{DISTROSYNC}->{called}, "Yum distrosync is called");

ok($cmp->{APPLY_TRANSACTION}->{called}, "Transaction application is called");
is($cmp->{APPLY_TRANSACTION}->{args}->[0], "install\nsolve\n",
   "Transaction application receives installation but not removal as argument");
is($cmp->{VERSIONLOCK}->{called}, 1, "Versions are locked");
is($cmp->{VERSIONLOCK}->{args}->[0], "pkgs",
   "Locked package versions with correct arguments");
is($cmp->{EXPIRE_YUM_CACHES}->{called}, 1, "Package cache is expired");

=pod

=item * When C<userpkgs> is false, it tries to remove outdated packages.

=cut

is($cmp->update_pkgs("pkgs", "groups", "run", 0), 1, "Basic run without userpkgs succeeds");
is($cmp->{PACKAGES_TO_REMOVE}->{called}, 1,
   "When userpkgs is disabled, it chooses packages for removal");
is(scalar(@{$cmp->{PACKAGES_TO_REMOVE}->{args}}), 1,
   "packages_to_remove called with the expected set of arguments");
is($cmp->{SCHEDULE}->{remove}->{called}, 1,
   "When userpkgs is disabled, the method tries to uninstall stuff");
is($cmp->{SCHEDULE}->{remove}->{args}->members(), 1,
   "Correct packages scheduled for removal without usrpkgs");
is($cmp->{APPLY_TRANSACTION}->{args}->[0], "remove\ninstall\nsolve\n",
   "Transaction application without userpkgs receives removal");

=pod

=item * When the transaction is empty, we still need to call Yum

Even if there is nothing new to install or to remove, versions of
packages may have changed, or we may need to synchronise with the
repository.

=cut

clear_mock_counters($cmp);
$cmp->{SCHEDULE}->{install}->{return} = "";
$cmp->{SCHEDULE}->{remove}->{return} = "";

is($cmp->update_pkgs("pkgs", "groups", "run", 0), 1, "Empty transaction succeeds");
is($cmp->{APPLY_TRANSACTION}->{called}, 0,
   "Empty transaction doesn't need Yum shell");

=pod

=back

=head2 Error handling

We simulate failures in the callees, from the end to the beginning. We
ensure that the return value is correct and that the execution stops
in the correct point.

=over

=cut

# For easier comparison, reset all call counters
clear_mock_counters($cmp);

=pod

=item * Failure in C<apply_transaction> means all methods get executed

=cut

$cmp->{APPLY_TRANSACTION}->{return} = 0;

is($cmp->update_pkgs("pkgs", "groups", "run", 0), 0,
   "Failure in apply_transaction is propagated");

foreach my $m (qw(apply_transaction solve_transaction
		  packages_to_remove wanted_pkgs installed_pkgs)) {
    is($cmp->{uc($m)}->{called}, 1,
       "Method $m called when apply_transaction fails");
}

is($cmp->{SCHEDULE}->{remove}->{called}, 1,
   "Schedule for removal when transaction fails");
is($cmp->{SCHEDULE}->{install}->{called}, 1,
   "Schedule for install when transaction fails");


=pod

=item * Failure in C<versionlock> means nothing is applied

=cut

clear_mock_counters($cmp);

$cmp->{VERSIONLOCK}->{return} = 0;

is($cmp->update_pkgs("pkgs", "groups", "run", 0), 0,
   "Failure in versionlock is detected");
is($cmp->{VERSIONLOCK}->{called}, 1, "versionlock is actually called");
is($cmp->{SOLVE_TRANSACTION}->{called}, 0,
   "solve_transaction is not called if versionlock fails");

=pod

=item * Failure in C<expire_yum_caches> means versionlock is not called

=cut

clear_mock_counters($cmp);
$cmp->{EXPIRE_YUM_CACHES}->{return} = 0;
is($cmp->update_pkgs("pkgs", "groups", "run", 0), 0,
   "Failure in versionlrmock is detected");
is($cmp->{EXPIRE_YUM_CACHES}->{called}, 1, "expire_yum_caches is actually called");
is($cmp->{VERSIONLOCK}->{called}, 0,
   "versionlock is not called if cache expiration fails");


=pod

=item * Failure in C<packages_to_remove> means apply_transaction is not called

=cut

clear_mock_counters($cmp);

$cmp->{PACKAGES_TO_REMOVE}->{return} = undef;

is($cmp->update_pkgs("pkgs", "groups", "run", 0), 0,
   "Failure in packages_to_remove is propagated");
is($cmp->{APPLY_TRANSACTION}->{called}, 0,
   "Apply transaction is not called when packages_to_remove fails");
is($cmp->{SOLVE_TRANSACTION}->{called}, 0,
   "Solve transaction is not called when packages_to_remove fails");

=pod

=item * Failure in C<installed_pkgs> means no scheduling is attempted.

=cut

clear_mock_counters($cmp);

$cmp->{INSTALLED_PKGS}->{return} = undef;

is($cmp->update_pkgs("pkgs", "groups", "run", 0), 0,
   "Failure in installed_pkgs is propagated");
is($cmp->{SCHEDULE}->{install}->{called}, 0,
   "No installation is scheduled if we cannot derive installed packages");
foreach my $m (qw(apply_transaction solve_transaction)) {
    is($cmp->{uc($m)}->{called}, 0,
       "Method $m not called when installed_pkgs fails");
}

is($cmp->{SCHEDULE}->{remove}->{called}, 0,
   "No removal scheduling when installed_pkgs fails");
is($cmp->{SCHEDULE}->{install}->{called}, 0,
   "No install scheduling when installed_pkgs fails");
is($cmp->{COMPLETE_TRANSACTION}->{called}, 1,
   "Transaction completion is always called");

clear_mock_counters($cmp);
$cmp->{COMPLETE_TRANSACTION}->{return} = 0;
is($cmp->update_pkgs("pkgs", "groups", "run", 0), 0,
   "Failure in complete_transaction is propagated");
is($cmp->{INSTALLED_PKGS}->{called}, 0,
   "Subsequent methods are not called if we can't complete previous transactions");

=pod

=item * Failure in C<expand_groups> means no scheduling is attempted

=cut

clear_mock_counters($cmp);
$cmp->{EXPAND_GROUPS}->{return} = undef;

is($cmp->update_pkgs("pkgs", "groups", "run", 0), 0,
   "Failure in expand_groups is propagated");
is($cmp->{SCHEDULE}->{remove}->{called}, 0,
   "No removal scheduling when group expansion fails");
is($cmp->{SCHEDULE}->{install}->{called}, 0,
   "No installation scheduling when group expansion fails");


=pod

=item * Failures in C<distrosync> are detected and propagated

=cut

clear_mock_counters();

$cmp->{DISTROSYNC}->{return} = 0;

is($cmp->update_pkgs("pkgs", "groups", "run", 0), 0,
   "Failure in distrosync is propagated");
is($cmp->{APPLY_TRANSACTION}->{called}, 0,
   "No transaction is attempted if distrosync fails");
is($cmp->{INSTALLED_PKGS}->{called}, 0,
   "No check for installed packages if distrosync fails");

done_testing();

=pod

=back

=cut
