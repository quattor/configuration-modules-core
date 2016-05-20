# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<make_cache> method.  This method creates
the cache to be used by all other yum/repoquery commands.

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

Readonly::Array my @MC_ORIG => NCM::Component::spma::yum::YUM_MAKECACHE();
Readonly::Array my @MC => @{NCM::Component::spma::yum::_set_yum_config(\@MC_ORIG)};
Readonly my $CMD => join(" ", @MC);

ok(! grep {$_ eq '-C'} @MC, 'yum makecache command has cache disabled');

my $cmp = NCM::Component::spma::yum->new("spma");

set_desired_output($CMD, "");
set_desired_err($CMD, "");

ok($cmp->make_cache(), "Successful execution detected");
ok(!$cmp->{ERROR}, "No errors reported");

my $cmd = get_command($CMD);
ok($cmd, "Correct command called");
is($cmd->{method}, "execute", "Correct method called");
# test for 0, to make sure it's defined and set to 0
is($cmd->{object}->{NoAction}, 0, "keeps_state set, NoAction set to 0");

set_command_status($CMD, 1);
ok(!$cmp->make_cache(), "Errors in make_cache detected");
is($cmp->{ERROR}, 1, "Errors reported");


done_testing();
