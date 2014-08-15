# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<purge_yum_caches> method.  This method removes the Yum
metadata before trying to modify the system.

=head1 TESTS

The tests are very simple: the correct command should be called, and
successes and errors must be propagated to the caller.

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use NCM::Component::spma::yum;
use Test::Quattor;

Readonly my $CMD => join(" ", NCM::Component::spma::yum::YUM_PURGE_METADATA);

my $cmp = NCM::Component::spma::yum->new("spma");

set_desired_output($CMD, "");
set_desired_err($CMD, "");

ok($cmp->purge_yum_caches(), "Successful execution detected");
ok(!$cmp->{ERROR}, "No errors reported");

my $cmd = get_command($CMD);
ok($cmd, "Correct command called");
is($cmd->{method}, "execute", "Correct method called");

set_command_status($CMD, 1);
ok(!$cmp->purge_yum_caches(), "Errors in cleanup detected");
is($cmp->{ERROR}, 1, "Errors reported");


done_testing();
