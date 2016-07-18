use strict;
use warnings;

use Test::More;
use Test::Quattor qw(client);
use Test::MockModule;

use mock_rpc qw(client);

use CAF::Object;

$CAF::Object::NoAction = 1;

my $mockk = Test::MockModule->new('CAF::Kerberos');
my $krb5;
my $context;
$mockk->mock('get_context', sub {$krb5 = shift; return $context});

use NCM::Component::freeipa;

my $cmp = NCM::Component::freeipa->new("freeipa");
my $cfg = get_config_for_profile("client");

=head2 Simple test

=cut

my $fqdn = $cmp->set_fqdn(config => $cfg);
my $tree = $cfg->getTree($cmp->prefix());
my $ipa;

$context = undef;

$ipa = $cmp->set_ipa_client($tree->{primary});
ok(! defined($ipa), "set_ipa_client returns undef if CAF::Kerberos get_context fails");
is_deeply($krb5->{ticket}, {keytab => '/etc/krb5.keytab'}, "Kerberos using correct ticket");
is_deeply($krb5->{principal}, {primary => 'host', instances => [$fqdn]}, "Kerberos using correct principal");

$context = 1;


# nick1 is not yet known
set_command_status('/usr/bin/certutil -d /etc/nssdb.quattor -L -n nick1', 1);

command_history_reset;

$ipa = $cmp->set_ipa_client($tree->{primary});
ok($cmp->client($tree), "client returns success");
ok(command_history_ok([
    "/usr/sbin/ipa-getkeytab -s myhost.example.com -p someservice1/myhost.example.com -k /etc/super1.keytab",
    "/usr/sbin/ipa-getkeytab -s myhost.example.com -p someservice2/myhost.example.com -k /etc/super2.keytab",
    "/usr/bin/certutil -d /etc/nssdb.quattor -N -f /dev/null",
    "/usr/bin/certutil -d /etc/nssdb.quattor -A -n MY.REALM IPA CA -t CT,, -a -i /etc/ipa/ca.crt",
    "/usr/bin/certutil -d /etc/nssdb.quattor -L -n nick1",
    "/usr/bin/certutil -d /etc/nssdb.quattor -R -g 4096 -s DN=nick1,CN=myhost.example.com,O=MY.REALM -z /tmp/quattor_nss-XXXX/random_nick1.data -a -o /tmp/quattor_nss-XXXX/cert_myhost.example.com_nick1.csr",
    "/usr/bin/certutil -d /etc/nssdb.quattor -A -n nick1 -t u,u,u -a -i /tmp/quattor_nss-XXXX/init_nss_nick1.crt",
    "/usr/bin/certutil -d /etc/nssdb.quattor -L -n nick1 -a -o /path/to/cert",
    "/usr/bin/pk12util -o /tmp/quattor_nss-XXXX/p12keys/key.p12 -n nick1 -d /etc/nssdb.quattor -W ",
    "/usr/bin/openssl pkcs12 -in /tmp/quattor_nss-XXXX/p12keys/key.p12 -out /path/to/key -nodes -password pass:",
]), "ipa-getkeytab and nss commands called");


diag explain $Test::Quattor::caf_path->{status};

is_deeply($Test::Quattor::caf_path->{status}, [
    [['/etc/super1.keytab'], {owner => 'root', group => 'root', mode => 0123}],
    [['/etc/super2.keytab'], {owner => 'root', group => 'superpower', mode => 0600}],
    [['/path/to/cert'], {owner => 'root', group => 'root', mode => 0644}], # default perm
    [['/path/to/key'], {owner => 'root', group => 'root', mode => 0600}], # default perm
], 'CAF::Path status called in keytabs');

done_testing();
