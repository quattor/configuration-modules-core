# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<update_pkgs_retry> method.

=head1 TESTS

This method just does nothing on its own. It just calls C<update_pkgs> method
so all testing is ensuring that the callees receive the correct
arguments.

=cut

use strict;
use warnings;

use Test::Quattor;
use Test::More;
use NCM::Component::spma::yum;
use Test::MockModule;

my $mock = Test::MockModule->new('NCM::Component::spma::yum');

my $called = 0;
my @args = ();
my @update_pkgs_ec;

$mock->mock("update_pkgs",  sub {
    my $self = shift;
	push(@args, \@_);
    $called++;
    return $update_pkgs_ec[$called -1];
});

my $cmp = NCM::Component::spma::yum->new("spma");

# first call returns success
$called = 0;
@update_pkgs_ec = qw(1);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 1, "purge", 0), 1,
   "Call with userpkgs=true, retry=false");
is($called, 1, "Basic invocation makes 1 update_pkgs call (with update_pkgs=success)");

# first call returns fail
$called = 0;
@update_pkgs_ec = qw(0);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 1, "purge", 0), 0,
   "Call with userpkgs=true, retry=false and update_pkgs=fail returns failure");
is($called, 1, "Basic invocation makes 1 update_pkgs call (with update_pkgs=fail, retry=false)");

# don't trigger retry with userpkgs allowed
$called = 0;
@update_pkgs_ec = qw(0);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 1, "purge", 1), 0,
   "Call with userpkgs=true, retry=true and update_pkgs=fail returns failure");
is($called, 1, "Invocation makes 1 update_pkgs call (with update_pkgs=fail, retry=true, userpkgs=true)");

# update_pkgs fails 2 times
$called = 0;
@args= ();
@update_pkgs_ec = qw(0 0);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 0, "purge", 1), 0,
   "Call with userpkgs=false, retry=true and update_pkgs=fail/fail returns failure");
is($called, 2, "Invocation makes 2 update_pkgs call (with update_pkgs=fail/fail, retry=true, userpkgs=false)");
# 2nd update_pkgs call is with updatepkgs enabled
is ($args[1]->[3], 1, "2nd update_pkgs call has userpkgs=true");

# updatepkgs fails 1st, success second, fails 3rd
$called = 0;
@args= ();
@update_pkgs_ec = qw(0 1 0);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 0, "purge", 1), 0,
   "Call with userpkgs=false, retry=true and update_pkgs=fail/success/fail returns failure");
is($called, 3, "Invocation makes 3 update_pkgs call (with update_pkgs=fail/success/fail, retry=true, userpkgs=false)");
# 2nd update_pkgs call is with updatepkgs enabled
is ($args[1]->[3], 1, "2nd update_pkgs call has userpkgs=true");
# 3rd update_pkgs call is with updatepkgs disabled
is ($args[2]->[3], 0, "3rd update_pkgs call has userpkgs=false");

# updatepkgs fails 1st, success second and 3rd
$called = 0;
@args= ();
@update_pkgs_ec = qw(0 1 1);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 0, "purge", 1), 1,
   "Call with userpkgs=false, retry=true and update_pkgs=fail/success/success returns success");
is($called, 3, "Invocation makes 3 update_pkgs call (with update_pkgs=fail/success/success, retry=true, userpkgs=false)");
# 2nd update_pkgs call is with updatepkgs enabled
is ($args[1]->[3], 1, "2nd update_pkgs call has userpkgs=true");
# 3rd update_pkgs call is with updatepkgs disabled
is ($args[2]->[3], 0, "3rd update_pkgs call has userpkgs=false");



done_testing();

=pod

=back

=cut
