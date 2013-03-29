# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<distro_sync> method.  This method just runs
C<yum -y distro-sync> and checks its errors.

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

Readonly my $CMD => join(" ", NCM::Component::spma::YUM_DISTRO_SYNC);

set_desired_err($CMD, "");
set_desired_output($CMD, "");

my $cmp = NCM::Component::spma->new("spma");

=pod

=back

=head2 Transaction completions

=cut

is($cmp->distrosync(), 1, "Basic distroync succeeds");;

my $cmd = get_command($CMD);
ok($cmd, "yum distro-sync was called");
is($cmd->{method}, "execute", "yum distro-sync was execute'd");

set_desired_err($CMD, "\nError: package");

is($cmp->distrosync(), 0, "Error in distro-sync detected");
is($cmp->{ERROR}, 1, "Error is reported");

set_command_status($CMD, 1);
set_desired_err($CMD, "Yabbadabadoo");
is($cmp->distrosync(), 0,
   "Error in Yum internals during distrosync detected");

set_command_status($CMD, 0);
is($cmp->distrosync(), 1, "yum distrosync succeeds even with minor warnings");

done_testing();
