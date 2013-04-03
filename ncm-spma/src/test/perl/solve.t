# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<solve_transaction> method.  This method just adds the
commands to solve and maybe run a transaction.

=head1 TESTS

If the C<run> parameter is set, the transaction must be executed

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use NCM::Component::spma;
use Test::Quattor;


my $cmp = NCM::Component::spma->new("spma");

my $tail = $cmp->solve_transaction(1);
is($tail, "transaction solve\ntransaction run\n",
   "Transaction correctly defined when the run parameter is set");
$tail = $cmp->solve_transaction(0);
is($tail, "transaction solve\ntransaction reset\n",
   "Transaction solved but not executed when run is not set");

$NCM::Component::NoAction = 1;
$tail = $cmp->solve_transaction(1);
is($tail, "transaction solve\ntransaction reset\n",
   "Transaction solved but not executed when NoAction is set");

done_testing();
