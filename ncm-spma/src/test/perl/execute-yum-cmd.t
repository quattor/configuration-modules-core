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
use NCM::Component::spma;
use Test::Quattor;
use CAF::Object;

$CAF::Object::NoAction = 1;

Readonly my $CMD => "foo bar bar";
Readonly my $WHY => "Hello world";

my $cmp = NCM::Component::spma->new("spma");


set_desired_output($CMD, "a");
set_desired_err($CMD, "");

is($cmp->execute_yum_command([$CMD], $WHY), "",
   "Successful execution detected");
ok(!$cmp->{ERROR}, "No errors reported");

my $cmd = get_command($CMD);

ok($cmd->{object}->{NoAction}, "keeps state is false");
ok($cmd, "Correct command called");
is($cmd->{method}, "execute", "Correct method called");

is($cmp->execute_yum_command([$CMD], $WHY, 1), "a",
   "Command with keep_state executed successfully");
$cmd = get_command($CMD);
ok(!$cmd->{object}->{NoAction}, "keeps_state passed correctly");

set_desired_err($CMD, "Error: foo bar!!");
is($cmp->execute_yum_command([$CMD], $WHY), undef, "Errors in output detected");

set_command_status($CMD, 1);
is($cmp->execute_yum_command([$CMD], $WHY), undef, "Errors in execution detected");
is($cmp->{ERROR}, 2, "Errors reported");


done_testing();
