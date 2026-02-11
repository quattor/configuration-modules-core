# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Tests for the C<execute_command> method in NCM::Component::spma::dnf.
This method executes shell commands and returns (exit code, stdout, stderr).

=head1 TESTS

The tests verify that commands are executed correctly and that
successes and errors are properly propagated to the caller.

=cut

use strict;
use warnings;
use Readonly;
use Test::More;
use Test::Quattor;
use NCM::Component::spma::dnf;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::spma::dnf->new("spma");

Readonly::Array my @TEST_CMD => ("echo", "test");
Readonly my $CMD_LINE => join(" ", @TEST_CMD);
Readonly my $WHY => "testing command execution";

=pod

=head2 Test successful command execution

=cut

set_desired_output($CMD_LINE, "test output");
set_desired_err($CMD_LINE, "");
set_command_status($CMD_LINE, 0);

my ($exit, $out, $err) = $cmp->execute_command(\@TEST_CMD, $WHY, 1);
is($exit, 0, "execute_command returns exit code 0 on success");
is($out, "test output", "execute_command captures stdout");
is($err, "", "execute_command captures empty stderr");

my $cmd = get_command($CMD_LINE);
ok($cmd, "Correct command called");
is($cmd->{method}, "execute", "Correct method called");

=pod

=head2 Test command with stderr output

=cut

set_desired_output($CMD_LINE, "stdout content");
set_desired_err($CMD_LINE, "stderr content");
set_command_status($CMD_LINE, 0);

($exit, $out, $err) = $cmp->execute_command(\@TEST_CMD, $WHY, 1);
is($exit, 0, "exit code 0 with stderr output");
is($out, "stdout content", "stdout captured correctly");
is($err, "stderr content", "stderr captured correctly");

=pod

=head2 Test command failure (non-zero exit)

=cut

set_desired_output($CMD_LINE, "");
set_desired_err($CMD_LINE, "error message");
set_command_status($CMD_LINE, 256);

($exit, $out, $err) = $cmp->execute_command(\@TEST_CMD, $WHY, 1);
isnt($exit, 0, "non-zero exit code returned on failure");
is($err, "error message", "error message captured");

=pod

=head2 Test keeps_state parameter

=cut

set_desired_output($CMD_LINE, "output");
set_desired_err($CMD_LINE, "");
set_command_status($CMD_LINE, 0);

($exit, $out, $err) = $cmp->execute_command(\@TEST_CMD, $WHY, 1);
$cmd = get_command($CMD_LINE);
ok(!$cmd->{object}->{NoAction}, "keeps_state=1 disables NoAction for command");

($exit, $out, $err) = $cmp->execute_command(\@TEST_CMD, $WHY, 0);
$cmd = get_command($CMD_LINE);
ok($cmd->{object}->{NoAction}, "keeps_state=0 keeps NoAction for command");

done_testing();
