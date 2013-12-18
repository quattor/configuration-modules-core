# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<apply_transaction> method.  This method executes the
transaction given as an argument into a Yum shell.

=head1 TESTS

=head2 Caches are cleaned

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;
use CAF::Object;
use Test::MockModule;

my $mock = Test::MockModule->new('NCM::Component::spma::yum');

$CAF::Object::NoAction = 1;

Readonly my $TX => "a transaction text";
Readonly my $YUM => join(" ", NCM::Component::spma::yum::YUM_CMD);

my $cmp = NCM::Component::spma::yum->new("spma");


set_desired_err($YUM, "");
set_desired_output($YUM, "Transaction");

=pod

=back

=head2 Transaction executions

=cut

ok($cmp->apply_transaction($TX), "Basic transaction succeeds");;

my $cmd = get_command($YUM);
ok($cmd, "Yum shell correctly called");
is($cmd->{method}, "execute", "Yum shell was execute'd");
like($cmd->{object}->{OPTIONS}->{stdin}, qr{$TX$},
   "Yum shell was given the correct transaction");

set_desired_err($YUM, "\nError: package");

ok(!$cmp->apply_transaction($TX), "Error in transaction detected");
is($cmp->{ERROR}, 1, "Error is reported");

set_command_status($YUM, 1);
set_desired_err($YUM, "Yabbadabadoo");
ok(!$cmp->apply_transaction($TX),
   "Error in Yum internals during transaction detected");

done_testing();
