# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<expire_yum_caches> method.  This method cleans up all
Yum caches before trying to modify the system.

=head1 TESTS

The tests are very simple: the correct command should be called, and
successes and errors must be propagated to the caller.

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::yum;
use CAF::Object;

$CAF::Object::NoAction = 1;

Readonly::Array my @YE_ORIG => NCM::Component::spma::yum::YUM_EXPIRE();
Readonly::Array my @YE => @{NCM::Component::spma::yum::_set_yum_config(\@YE_ORIG)};
Readonly my $CMD => join(" ", @YE);

ok(! grep {$_ eq '-C'} @YE, 'yum expire command has cache disabled');

my $cmp = NCM::Component::spma::yum->new("spma");

set_desired_output($CMD, "");
set_desired_err($CMD, "");

ok($cmp->expire_yum_caches(), "Successful execution detected");
ok(!$cmp->{ERROR}, "No errors reported");

my $cmd = get_command($CMD);
ok($cmd, "Correct command called");
is($cmd->{method}, "execute", "Correct method called");
# test for 0, to make sure it's defined and set to 0
is($cmd->{object}->{NoAction}, 0, "keeps_state set, NoAction set to 0");

set_command_status($CMD, 1);
ok(!$cmp->expire_yum_caches(), "Errors in cleanup detected");
is($cmp->{ERROR}, 1, "Errors reported");


done_testing();
