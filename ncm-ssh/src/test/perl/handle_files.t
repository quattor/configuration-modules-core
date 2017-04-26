# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(files);
use CAF::Object;
use NCM::Component::ssh;
use Readonly;
use CAF::FileWriter;
use Test::MockModule;

my $mock = Test::MockModule->new("CAF::FileWriter");

my $cancelled = 0;
# Mock the cancel method to know if it was actually called.
# The component may call it as a second time.
$mock->mock("cancel", sub {
    $cancelled++ if ref($_[0]) ne 'CAF::FileReader';
    return $mock->original('cancel')->(@_);
});

Readonly my $SSH_FILE => "target/test/sshd";
Readonly my $SSH_FILE_CLIENT => "target/test/ssh_client";

Readonly my $SSH_CONTENTS => "Foo bar baz\nAllowGroups a b";

my $fh = CAF::FileWriter->new($SSH_FILE);
print $fh $SSH_CONTENTS;
$fh->close();

=pod

=head1 DESCRIPTION

Test how the config files are handled.  Exercises the
C<handle_config_file> method.

The component requires some heavy refactoring, but first we need some
basic tests to ensure we don't break the old behaviour.

=cut

my $cfg = get_config_for_profile('files');
my $cmp = NCM::Component::ssh->new('ssh');

my $t = $cfg->getElement("/software/components/ssh/daemon")->getTree();
$cancelled = 0;
$cmp->handle_config_file($SSH_FILE, 0600, $t);
$fh = get_file($SSH_FILE);
like($fh, qr{^AllowGroups\s+a b c$}m, "Multiword option accepted and modified correctly");

is($cancelled, 0, "File with no validation is written");

$cmp->handle_config_file($SSH_FILE, 0600, $t, sub { return 1; });

$fh = get_file($SSH_FILE);
is($cancelled, 0, "File with successful validation is written");

$cmp->handle_config_file($SSH_FILE, 0600, $t, sub { return 0; });
$fh = get_file($SSH_FILE);
is($cancelled, 1, "Invalid file is not written");

# test the client file too
$cmp->handle_config_file($SSH_FILE_CLIENT, 0644,
                         $cfg->getElement("/software/components/ssh/client")->getTree());
my $client = get_file($SSH_FILE_CLIENT);
like("$client", qr{^Port 22222$}m, "Port number set");
like("$client", qr{^PreferredAuthentications gssapi-with-mic,hostbased,publickey$}m, "PreferredAuthentications list set");

done_testing();
