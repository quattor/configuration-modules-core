use strict;
use warnings;

use Test::More;
use Test::Quattor qw(client);
use Test::MockModule;

my $mock = Test::MockModule->new('CAF::Check');
my $status = [];
$mock->mock('status', sub {
    my ($self, $path, %opts) = @_;
    push (@$status, [$path, \%opts]);
    return 1;
});

use NCM::Component::freeipa;

my $cmp = NCM::Component::freeipa->new("freeipa");
my $cfg = get_config_for_profile("client");
my $tree;

=head2 Simple test

=cut

my $tree = $cfg->getTree($cmp->prefix());

command_history_reset;
ok($cmp->client($cfg, $tree), "client returns success");
ok(command_history_ok([
   "/usr/sbin/ipa-getkeytab -s myhost.example.com -p someservice1/myhost.example.com -k /etc/super1.keytab",
   "/usr/sbin/ipa-getkeytab -s myhost.example.com -p someservice2/myhost.example.com -k /etc/super2.keytab",
]), "ipa-getkeytab called");

is_deeply($status, [
    ['/etc/super1.keytab', {owner => 'root', group => 'root', mode => 0123}],
    ['/etc/super2.keytab', {owner => 'root', group => 'superpower', mode => 0600}],
], 'CAF::Check status called in keytabs');


done_testing();
