use strict;
use warnings;
use Test::More;
use Test::Quattor qw(commands commands_fail_pre);
use NCM::Component::metaconfig;
use Test::MockModule;

=pod

=head1 DESCRIPTION

Test the configure() method.

=cut

my $orig = 'X';

sub clean
{
    set_file_contents("/foo/bar", "$orig");
    command_history_reset();
}

my $cmp = NCM::Component::metaconfig->new('metaconfig');
my $cfg = get_config_for_profile('commands');
my $cfg_fail = get_config_for_profile('commands_fail_pre');

clean();

is($cmp->Configure($cfg), 1, "Configure succeeds");
my $fh = get_file("/foo/bar");
ok($orig ne "$fh", "orig content is not same as current $fh");

ok($fh, "A file was actually created");
isa_ok($fh, "CAF::FileWriter");

# if default sysv init service changes, also modify the aii_command negative test
ok(command_history_ok(['/cmd pre', '/cmd test', '/cmd changed', '/cmd post', 'service foo restart']),
   "commands run and serivce foo restarted");

clean();

# changed failed, post does not run, daemons does run
set_command_status('/cmd changed', 1);
$cmp->Configure($cfg);
ok(command_history_ok(['/cmd pre', '/cmd test', '/cmd changed', 'service foo restart'], ['/cmd post']),
   "commands except post run and serivce foo restarted");
my $fcnt = get_file_contents("/foo/bar");
ok($orig ne "$fcnt", "orig content is not same as current $fcnt");

clean();

# test failed, changed, post and daemons do not run, content unmodified
set_command_status('/cmd test', 1);
$cmp->Configure($cfg);
ok(command_history_ok(['/cmd pre', '/cmd test'], ['/cmd changed', 'service foo restart', '/cmd post']),
   "commands run except changed, post and no serivce foo restarted");
$fcnt = get_file_contents("/foo/bar");
# unmodified
is($orig, "$fcnt", "orig content is same as current $fcnt on test failed");

clean();
# pre failed, test, changed, post and daemons do not run, content unmodified
set_command_status('/cmd pre', 1);
$cmp->Configure($cfg);
ok(command_history_ok(['/cmd pre'], ['/cmd test', '/cmd changed', 'service foo restart', '/cmd post']),
   "commands run except test, changed, post and no serivce foo restarted");
$fcnt = get_file_contents("/foo/bar");
# unmodified
is($orig, "$fcnt", "orig content is same as current $fcnt on pre failed");

clean();
# Rerun with cmd_pre that can fail. Test still fails as usual
$cmp->Configure($cfg_fail);
ok(command_history_ok(['/cmd pre', '/cmd test'], ['/cmd changed', 'service foo restart', '/cmd post']),
   "commands pre fails, but is ok so still runs test, and no changed, post and no serivce foo restarted");
$fcnt = get_file_contents("/foo/bar");
# unmodified
is($orig, "$fcnt", "orig content is same as current $fcnt on pre failed but ok to fail and test fails");


done_testing();
