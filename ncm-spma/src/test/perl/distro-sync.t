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
use NCM::Component::spma;
use CAF::Object;

Readonly my $CMD => join(" ", NCM::Component::spma::YUM_DISTRO_SYNC);

set_desired_err($CMD, "");
set_desired_output($CMD, "");

my $cmp = NCM::Component::spma->new("spma");

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

is($cmp->distrosync(1), 1, "Basic distroync succeeds");;

$cmd = get_command($CMD);
ok($cmd, "yum distro-sync was called");
is($cmd->{method}, "execute", "yum distro-sync was execute'd");

set_desired_err($CMD, "\nError: package");

is($cmp->distrosync(1), 0, "Error in distro-sync detected");
is($cmp->{ERROR}, 1, "Error is reported");

set_command_status($CMD, 1);
set_desired_err($CMD, "Yabbadabadoo");
is($cmp->distrosync(1), 0,
   "Error in Yum internals during distrosync detected");

set_command_status($CMD, 0);
is($cmp->distrosync(1), 1, "yum distrosync succeeds even with minor warnings");

done_testing();
