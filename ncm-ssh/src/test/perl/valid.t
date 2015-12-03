# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use CAF::Object;
use NCM::Component::ssh;
use Readonly;

my $cmd = join(" ", (NCM::Component::ssh::DEFAULT_SSHD_PATH, '-t', '-f', '/dev/stdin'));

my $cmp = NCM::Component::ssh->new("ssh");

=pod

=head1 DESCRIPTION

Test for the C<valid_ssh_file> predicate.

=cut

set_command_status($cmd, 0);
ok($cmp->valid_sshd_file("foo"), "Success upon valid file");

set_command_status($cmd, 1);
set_desired_err($cmd, "Error");
ok(!$cmp->valid_sshd_file("foo"), "Invalid file is detected");

done_testing();
