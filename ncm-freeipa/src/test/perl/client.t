use strict;
use warnings;

use Test::More;
use Test::Quattor qw(client);
use Test::MockModule;

my $mockc = Test::MockModule->new('CAF::Check');
my $status = [];
$mockc->mock('status', sub {
    my ($self, $path, %opts) = @_;
    push (@$status, [$path, \%opts]);
    return 1;
});

my $mockk = Test::MockModule->new('CAF::Kerberos');
my $krb5;
my $context;
$mockk->mock('get_context', sub {$krb5 = shift; return $context});

use NCM::Component::freeipa;

my $cmp = NCM::Component::freeipa->new("freeipa");
my $cfg = get_config_for_profile("client");
my $tree;

=head2 Simple test

=cut

my $network = $cfg->getTree('/system/network');
my $fqdn = "$network->{hostname}.$network->{domainname}";
my $tree = $cfg->getTree($cmp->prefix());

$context = undef;
ok(! defined($cmp->client($fqdn, $tree)), "client returns undef if CAF::Kerberos get_context fails");
is_deeply($krb5->{ticket}, {keytab => '/etc/krb5.keytab'}, "Kerberos using correct ticket");
is_deeply($krb5->{principal}, {primary => 'host', instances => [$fqdn]}, "Kerberos using correct principal");

$context = 1;

command_history_reset;

ok($cmp->client($fqdn, $tree), "client returns success");
ok(command_history_ok([
   "/usr/sbin/ipa-getkeytab -s myhost.example.com -p someservice1/myhost.example.com -k /etc/super1.keytab",
   "/usr/sbin/ipa-getkeytab -s myhost.example.com -p someservice2/myhost.example.com -k /etc/super2.keytab",
]), "ipa-getkeytab called");

is_deeply($status, [
    ['/etc/super1.keytab', {owner => 'root', group => 'root', mode => 0123}],
    ['/etc/super2.keytab', {owner => 'root', group => 'superpower', mode => 0600}],
], 'CAF::Check status called in keytabs');


done_testing();
