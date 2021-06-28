# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<distro_sync> method.  This method just runs
C<yum -y distro-sync> and checks its errors.

=head1 TESTS

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;
use CAF::Object;

my $cmp = NCM::Component::spma::yum->new("spma");

Readonly::Array my @YDS_ORIG => NCM::Component::spma::yum::YUM_DISTRO_SYNC();
Readonly::Array my @YDS => @{$cmp->_set_yum_config(\@YDS_ORIG)};
Readonly my $CMD => join(" ", @YDS);
Readonly my $CMDP => "$CMD a b";

set_desired_err($CMD, "");
set_desired_output($CMD, "distrosync");
set_desired_err($CMDP, "");
set_desired_output($CMDP, "distrosync with packages a b");

ok(! grep {$_ eq '-C'} @YDS, 'distrosync command has cache disabled');

=pod

=head2 When C<runspma> is false

The method should always succeed, but no command should be run.

=cut

is($cmp->distrosync(0), 1, "The method succeeds if Yum is not allowed");

my $cmd = get_command($CMD);
ok(!$cmd, "No Yum command is run if not allowed");

=pod

=head2 When C<runspma> is true

Yum distro-sync should always run.  The return value reflects whether
it succeeded or not.

=cut

ok($cmp->distrosync(1), "Basic distrosync succeeds");;

$cmd = get_command($CMD);
ok($cmd, "yum distro-sync was called");
is($cmd->{method}, "execute", "yum distro-sync was execute'd");

ok($cmp->distrosync(1, ['a', 'b']), "Basic distrosync with packages succeeds");
$cmd = get_command($CMDP);
ok($cmd, "yum distro-sync was called with packages");
is($cmd->{method}, "execute", "yum distro-sync with packages was execute'd");


set_desired_err($CMD, "\nError: package");

ok(!$cmp->distrosync(1), "Error in distro-sync detected");
is($cmp->{ERROR}, 1, "Error is reported");

set_command_status($CMD, 1);
set_desired_err($CMD, "Yabbadabadoo");
ok(!$cmp->distrosync(1),
   "Error in Yum internals during distrosync detected");

set_command_status($CMD, 0);
ok($cmp->distrosync(1), "yum distrosync succeeds even with minor warnings");

done_testing();
