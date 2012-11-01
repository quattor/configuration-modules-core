# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(files);
use CAF::Object;
use NCM::Component::ssh;
use Readonly;
use CAF::FileWriter;

Readonly my $SSH_FILE => "target/test/sshd";
Readonly my $SSH_CONTENTS => "Foo bar baz\n";

my $fh = CAF::FileWriter->new($SSH_FILE);
print $fh $SSH_CONTENTS;
$fh->close();


=pod

=head1 DESCRIPTION

Basic test that ensures the component runs.

The component requires some heavy refactoring, but first we need some
basic tests to ensure we don't break the old behaviour.

=cut

$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('files');
my $cmp = NCM::Component::ssh->new('ssh');

my $t = $cfg->getElement("/software/components/ssh/daemon")->getTree();
$cmp->handle_config_file($SSH_FILE, 0600, $t);
$fh = get_file($SSH_FILE);
like($fh, qr{^AllowGroups\s+a b c$}m, "Multiword option accepted");

done_testing();
