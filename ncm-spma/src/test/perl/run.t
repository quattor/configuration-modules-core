# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<apply_transaction> method.  This method executes the
transaction given as an argument into a Yum shell.

=head1 TESTS

This is fairly straightforward: check that Yum is called, and what the
behaviour is upon success or failure.

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use NCM::Component::spma;
use Test::Quattor;
use CAF::Object;

$CAF::Object::NoAction = 1;

Readonly my $TX => "a transaction text";
Readonly my $YUM => join(" ", @{NCM::Component::spma::YUM_CMD()});

my $cmp = NCM::Component::spma->new("spma");

is($cmp->apply_transaction($TX), 1, "Transaction succeeds in normal conditions");
ok(!$cmp->{ERROR}, "No errors reported");
is($cmp->{INFO}, 1, "Yum output reported");

my $cmd = get_command($YUM);
ok($cmd, "Yum shell correctly called");
is($cmd->{method}, "execute", "Yum shell was execute'd");
is($cmd->{object}->{OPTIONS}->{stdin}, $TX,
   "Yum shell was given the correct transaction");

set_command_status($YUM, 1);
ok(!$cmp->apply_transaction($TX), "Transaction failure is propagated");
is($cmp->{ERROR}, 1, "Transaction error is reported");

done_testing();
