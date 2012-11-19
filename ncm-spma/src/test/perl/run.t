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
use NCM::Component::spma;
use CAF::Object;
use Test::MockModule;

my $mock = Test::MockModule->new('NCM::Component::spma');
$mock->mock('expire_yum_caches', sub {
		my $self = shift;
		$self->{EXPIRE_YUM_CACHES}->{called}++;
		return $self->{EXPIRE_YUM_CACHES}->{return} // 1;
	    });

$CAF::Object::NoAction = 1;

Readonly my $TX => "a transaction text";
Readonly my $YUM => join(" ", NCM::Component::spma::YUM_CMD);

my $cmp = NCM::Component::spma->new("spma");


set_desired_err($YUM, "");
set_desired_output($YUM, "");

=pod

=over 4

=item * A failure in the cache cleaning is reported, and the transaction is not run

=cut

$cmp->{EXPIRE_YUM_CACHES}->{return} = 0;
is($cmp->apply_transaction($TX), 0, "Failure in cache cleanup reported");
is($cmp->{EXPIRE_YUM_CACHES}->{called}, 1, "Expiration called");
ok(!get_command($YUM), "Failure in cache cleanup prevents transaction execution");

=pod

=over 4

=item * Successes in the cleanup of caches allow for transaction execution

=head2 Transaction executions

=cut

$cmp->{EXPIRE_YUM_CACHES}->{return} = 1;
is($cmp->apply_transaction($TX), 1, "Transaction succeeds in normal conditions");

is($cmp->{EXPIRE_YUM_CACHES}->{called}, 2,
   "Expiration called in successful transactions");

my $cmd = get_command($YUM);
ok($cmd, "Yum shell correctly called");
is($cmd->{method}, "execute", "Yum shell was execute'd");
like($cmd->{object}->{OPTIONS}->{stdin}, qr{$TX$},
   "Yum shell was given the correct transaction");

set_desired_err($YUM, "\nError: package");

is($cmp->apply_transaction($TX), 0, "Error in transaction detected");
is($cmp->{ERROR}, 1, "Error is reported");

set_command_status($YUM, 1);
set_desired_err($YUM, "Yabbadabadoo");
is($cmp->apply_transaction($TX), 0,
   "Error in Yum internals during transaction detected");

done_testing();
