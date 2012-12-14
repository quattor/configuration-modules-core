# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<complete_transaction> method.  This method just runs
yum-complete-transaction and checks its errors.

=head1 TESTS

=head2 Caches are cleaned

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma;
use CAF::Object;
use Test::MockModule;

Readonly my $CMD => NCM::Component::spma::YUM_COMPLETE_TRANSACTION;

set_desired_err($CMD, "");
set_desired_output($CMD, "");

my $cmp = NCM::Component::spma->new("spma");

=pod

=back

=head2 Transaction completions

=cut

is($cmp->complete_transaction(), 1, "Basic transaction completion succeeds");;

my $cmd = get_command($CMD);
ok($cmd, "yum-complete-transaction was called");
is($cmd->{method}, "execute", "yum-complete-transaction was execute'd");

set_desired_err($CMD, "\nError: package");

is($cmp->complete_transaction(), 0, "Error in transaction completion detected");
is($cmp->{ERROR}, 1, "Error is reported");

set_command_status($CMD, 1);
set_desired_err($CMD, "Yabbadabadoo");
is($cmp->complete_transaction(), 0,
   "Error in Yum internals during transaction detected");

set_command_status($CMD, 0);
is($cmp->complete_transaction(), 1,
   "Transaction succeeds even with minor warnings");

done_testing();
