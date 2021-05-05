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
use Test::Quattor;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::spma::yum->new("spma");

# Test _set_yum_config
# Only the default config is active
is_deeply($cmp->_set_yum_config([qw(a b c)]),
         ['a', '-c', '/etc/yum.conf', 'b', 'c'], "Inserted (default) yum config");
is_deeply($cmp->_set_yum_config([qw(a)]),
         ['a', '-c', '/etc/yum.conf'], "Inserted (default) yum config (no other args)");


Readonly::Array my @CMD => ["foo", "bar", "bar"];
Readonly my $CMD_LINE => join(" ", @{$cmp->_set_yum_config(\@CMD)});

Readonly my $WHY => "Hello world";



set_desired_output($CMD_LINE, "a");
set_desired_err($CMD_LINE, "");

is($cmp->execute_yum_command(\@CMD, $WHY), 1,
   "Successful execution detected");
ok(!$cmp->{ERROR}, "No errors reported");

my $cmd = get_command($CMD_LINE);

ok($cmd->{object}->{NoAction}, "keeps state is false");
ok($cmd, "Correct command called");
is($cmd->{method}, "execute", "Correct method called");

is($cmp->execute_yum_command(\@CMD, $WHY, 1), "a",
   "Command with keep_state executed successfully");
$cmd = get_command($CMD_LINE);
ok(!$cmd->{object}->{NoAction}, "keeps_state passed correctly");

set_desired_err($CMD_LINE, "Error: foo bar!!");
is($cmp->execute_yum_command(\@CMD, $WHY), undef, "Errors in output detected");
my $errs_reported = $cmp->{ERROR};
my $warns_reported = $cmp->{WARN};
is($errs_reported, 1, "Errors reported");

is($cmp->execute_yum_command(\@CMD, $WHY, undef, undef, "error"), undef, "Errors in output detected (error logger set)");
is($cmp->{ERROR}, $errs_reported + 1, "1 new error reported (error logger set)".$cmp->{ERROR});
my $new_warns = $cmp->{WARN} - $warns_reported;
$errs_reported = $cmp->{ERROR};
$warns_reported = $cmp->{WARN};

is($cmp->execute_yum_command(\@CMD, $WHY, undef, undef, "warn"), undef, "Errors in output detected (warn logger set)");
is($cmp->{ERROR}, $errs_reported, "0 new errors reported (warn logger set)");
is($cmp->{WARN}, $warns_reported + $new_warns + 1, "1 additional new warn reported (warn logger set; 1 previous-logged-as-error now a warn)");

set_desired_err($CMD_LINE, "Error in PREIN scriptlet");

is($cmp->execute_yum_command(\@CMD, $WHY), undef,
   "Errors in scriptlet execution detected, see issue #42");

set_desired_err($CMD_LINE, "ERROR foo bar");
is($cmp->execute_yum_command(\@CMD, $WHY), undef,
   "Yet another error string is detected");

set_desired_err($CMD_LINE, "Transaction encountered a serious error");
is($cmp->execute_yum_command(\@CMD, $WHY), undef,
   "Yet another Yum error is correctly diagnosed");

set_desired_err($CMD_LINE, "Failed to do stuff");
is($cmp->execute_yum_command(\@CMD, $WHY), undef, "Failed is a Yum error");

set_desired_err($CMD_LINE, "Failed loading plugin huppeldepup");
is($cmp->execute_yum_command(\@CMD, $WHY), 1,
   "Failed to load a plugin is not a Yum error");

set_desired_err($CMD_LINE,
                join(" ", qw{https://foobar.xml: [Errno 14] PYCURL ERROR 22 -
                             "The requested URL returned error: 403 Forbidden"}),
                "Unreachable repositories detected");

set_desired_err($CMD_LINE, "");
set_desired_output($CMD_LINE, "No package foo available");

is($cmp->execute_yum_command(\@CMD, $WHY), undef,
   "Unavailable packages detected and alerted");

set_command_status($CMD_LINE, 1);
is($cmp->execute_yum_command(\@CMD, $WHY), undef, "Errors in execution detected");

done_testing();
