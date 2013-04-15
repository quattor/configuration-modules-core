# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use CAF::Object;
use NCM::Component::ssh;
use Readonly;

Readonly my $CMD => join(" ", NCM::Component::ssh::SSH_VALIDATE);

my $cmp = NCM::Component::ssh->new("ssh");

=pod

=head1 DESCRIPTION

Test for the C<valid_ssh_file> predicate.

=cut

set_command_status($CMD, 0);
ok($cmp->valid_sshd_file("foo"), "Success upon valid file");

set_command_status($CMD, 1);
set_desired_err($CMD, "Error");
ok(!$cmp->valid_sshd_file("foo"), "Invalid file is detected");

done_testing();
