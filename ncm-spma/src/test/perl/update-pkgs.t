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

This method just does nothing on its own. It just calls other methodsm
so all testing is ensuring that the callees receive the correct
arguments.

=cut

use strict;
use warnings;
use Readonly;


use Test::Quattor;
use Test::More;
use NCM::Component::spma;

use File::Path qw(mkpath rmtree);
use LC::File;

use Set::Scalar;

# Actually, this update_pkgs just coordinates a set of other methods,
# which are not relevant for this testing script. For that purpose, we
# override them.
#
# All our backup methods will return 1 unless specified by the test
# script.
no warnings 'redefine';
no strict 'refs';
foreach my $method (qw(installed_pkgs wanted_pkgs apply_transaction
		       schedule_install schedule_removal solve_transaction)) {
    *{"NCM::Component::spma::$method"} = sub {
	my $self = shift;
	$self->{uc($method)}->{args} = \@_;
	$self->{uc($method)}->{called}++;
	return exists($self->{uc($method)}->{return}) ?
	  $self->{uc($method)}->{return} : 1;
    };
}

use warnings 'redefine';
use strict 'refs';

my $cmp = NCM::Component::spma->new("spma");

my $pkgs = {};
$cmp->{WANTED_PKGS}->{return} = 5;
$cmp->{INSTALLED_PKGS}->{return} = 3;
$cmp->{SCHEDULE_REMOVAL}->{return} = "remove\n";
$cmp->{SCHEDULE_INSTALL}->{return} = "install\n";
$cmp->{SOLVE_TRANSACTION}->{return} = "solve\n";
$cmp->{APPLY_TRANSACTION}->{return} = "apply";

is($cmp->update_pkgs("pkgs", "run", "allow"), 1,
   "Basic invocation returns success");
is($cmp->{INSTALLED_PKGS}->{called}, 1, "Installed packages called");
is(scalar(@{$cmp->{INSTALLED_PKGS}->{args}}), 0,
   "Installed packages called with no arguments");
is($cmp->{WANTED_PKGS}->{args}->[0], "pkgs",
   "wanted_pkgs receives the expected arguments");
ok(!$cmp->{SCHEDULE_REMOVAL}->{called},
   "When allow user packages, nothing is scheduled for removal");




done_testing();
