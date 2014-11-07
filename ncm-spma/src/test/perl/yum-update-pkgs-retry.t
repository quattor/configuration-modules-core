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
    note("update_pkgs called $called args (".join(', ', @_).').');
    return $update_pkgs_ec[$called -1];
});

my $cmp = NCM::Component::spma::yum->new("spma");

=pod

=head2 Update success

First call returns success

=cut 


$called = 0;
@args= ();
$cmp->{ERROR} = 0;
@update_pkgs_ec = qw(1);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 1, "purge", 0, "fullsearch"), 1,
   "Call with userpkgs=true, retry=false");
is($called, 1, "Basic invocation makes 1 update_pkgs call (with update_pkgs=success)");
ok (! $args[0]->[5], "1st (and only) update_pkgs call has tx_error_is_warn=false");
is ($cmp->{ERROR}, 0, "No errors logged");

=pod

=head2 Update fails, no retry

First call returns fail, no retry allowed

=cut 

$called = 0;
@args= ();
$cmp->{ERROR} = 0;
@update_pkgs_ec = qw(0);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 1, "purge", 0, "fullsearch"), 0,
   "Call with userpkgs=true, retry=false and update_pkgs=fail returns failure");
is($called, 1, "Basic invocation makes 1 update_pkgs call (with update_pkgs=fail, retry=false)");
ok (! $args[0]->[5], "1st (and only) update_pkgs call has tx_error_is_warn=false");
is ($cmp->{ERROR}, 0, "No errors logged by update_pkgs_retry (expect something else to log them)");

=pod

=head2 Update fails, userpaks and retry allowed

Don't trigger retry with userpkgs allowed

=cut 

$called = 0;
@args= ();
$cmp->{ERROR} = 0;
@update_pkgs_ec = qw(0);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 1, "purge", 1, "fullsearch"), 0,
   "Call with userpkgs=true, retry=true and update_pkgs=fail returns failure");
is($called, 1, "Invocation makes 1 update_pkgs call (with update_pkgs=fail, retry=true, userpkgs=true)");
ok(! $args[0]->[5], "1st (and only) update_pkgs call has tx_error_is_warn=false");
is ($cmp->{ERROR}, 0, "No errors logged by update_pkgs_retry (expect something else to log them)");

=pod

=head2 Update fails twice

update_pkgs fails 2 times (2nd failure with user pakgs allowed)

=cut 


$called = 0;
@args= ();
$cmp->{ERROR} = 0;
@update_pkgs_ec = qw(0 0);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 0, "purge", 1, "fullsearch"), 0,
   "Call with userpkgs=false, retry=true and update_pkgs=fail/fail returns failure");
is($called, 2, "Invocation makes 2 update_pkgs call (with update_pkgs=fail/fail, retry=true, userpkgs=false)");

# 1st update_pkgs no error (tx_error_is_warn=1)
ok ($args[0]->[5], "1st update_pkgs call has tx_error_is_warn=true");

# 2nd update_pkgs call is with updatepkgs enabled
is ($args[1]->[3], 1, "2nd update_pkgs call has userpkgs=true");
ok (! $args[1]->[5], "2nd update_pkgs call has tx_error_is_warn=false");

is ($cmp->{ERROR}, 1, "1 error logged by update_pkgs_retry");


=pod

=head2 Update fails with userpakages not allowed

update_pkgs fails 1st, success second (with userpackages allowed), fails 3rd (with userpackages not allowed)

=cut 

$called = 0;
@args= ();
$cmp->{ERROR} = 0;
@update_pkgs_ec = qw(0 1 0);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 0, "purge", 1, "fullsearch"), 0,
   "Call with userpkgs=false, retry=true and update_pkgs=fail/success/fail returns failure");
is($called, 3, "Invocation makes 3 update_pkgs call (with update_pkgs=fail/success/fail, retry=true, userpkgs=false)");
ok ($args[0]->[5], "1st update_pkgs call has tx_error_is_warn=true");
# 2nd update_pkgs call is with updatepkgs enabled
is ($args[1]->[3], 1, "2nd update_pkgs call has userpkgs=true");
ok (! $args[1]->[5], "2nd update_pkgs call has tx_error_is_warn=false");
# 3rd update_pkgs call is with updatepkgs disabled
is ($args[2]->[3], 0, "3rd update_pkgs call has userpkgs=false");
ok (! $args[2]->[5], "3rd update_pkgs call has tx_error_is_warn=false");

is ($cmp->{ERROR}, 1, "1 error logged by update_pkgs_retry");

=pod

=head2 Succesful retry

update_pkgs fails 1st, success second and 3rd

=cut 

$called = 0;
@args= ();
$cmp->{ERROR} = 0;
@update_pkgs_ec = qw(0 1 1);
is($cmp->update_pkgs_retry("pkgs", "groups", "run", 0, "purge", 1, "fullsearch"), 1,
   "Call with userpkgs=false, retry=true and update_pkgs=fail/success/success returns success");
is($called, 3, "Invocation makes 3 update_pkgs call (with update_pkgs=fail/success/success, retry=true, userpkgs=false)");
ok ($args[0]->[5], "1st update_pkgs call has tx_error_is_warn=true");
# 2nd update_pkgs call is with updatepkgs enabled
is ($args[1]->[3], 1, "2nd update_pkgs call has userpkgs=true");
ok (! $args[1]->[5], "2nd update_pkgs call has tx_error_is_warn=false");
# 3rd update_pkgs call is with updatepkgs disabled
is ($args[2]->[3], 0, "3rd update_pkgs call has userpkgs=false");
ok (! $args[2]->[5], "3rd update_pkgs call has tx_error_is_warn=false");

is ($cmp->{ERROR}, 0, "No error logged by update_pkgs_retry");

=pod

=head2 Test all expected arguments are passed 

In succesful retry, the 3 update_pkgs calls receive all expected arguments

=cut 

# reuse last data
is_deeply($args[0], ["pkgs", "groups", "run", 0, "purge", 1, "fullsearch"], "1st update_pkgs expected args");
is_deeply($args[1], ["pkgs", "groups", "run", 1, "purge", 0, "fullsearch"], "2nd update_pkgs expected args");
is_deeply($args[2], ["pkgs", "groups", "run", 0, "purge", 0, "fullsearch"], "3rd update_pkgs expected args");


done_testing();

=pod

=back

=cut
