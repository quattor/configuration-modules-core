# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(ssh_simple empty);
use CAF::Object;
use File::Path qw(mkpath);
use NCM::Component::ssh;
use Test::MockModule;


$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.  Ensure the methods are
called when they have configurations associated, and that the daemon
is restarted when needed.

=cut

my $mock = Test::MockModule->new('NCM::Component::ssh');

my $cfg = get_config_for_profile('ssh_simple');
my $cmp = NCM::Component::ssh->new('ssh');
$mock->mock(handle_config_file => 0);

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");
my $cmd = get_command("/sbin/service sshd condrestart");
ok(!$cmd, "Daemon is not restarted when nothing changes");

$mock->mock(handle_config_file => 1);
$cmp->Configure($cfg);
$cmd = get_command("/sbin/service sshd condrestart");
ok($cmd, "Daemon is restarted when something changes");
set_command_status("/sbin/service sshd condrestart", 1);
is($cmp->Configure($cfg), 0, "Failures in restart are propagated");


$mock->mock(handle_config_file => sub {
		my $self = shift;
		$self->{HANDLE_CONFIG_FILE}->{called} = 1;
		return 0;
	    });
$cfg = get_config_for_profile('empty');
is($cmp->Configure($cfg), 1, "Executions on empty subtress succeed");

done_testing();
