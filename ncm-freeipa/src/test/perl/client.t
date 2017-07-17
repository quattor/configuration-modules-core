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
$mockk->mock('get_context', sub {
    $krb5 = shift;
    $krb5->{fail} = 'mocked failed context' if ! $context;
    return $context
});

use NCM::Component::freeipa;

=head2 constants

=cut

is($NCM::Component::freeipa::IPA_QUATTOR_BASEDIR, "/etc/ipa/quattor", "basedir for ncm-freeipa / quattor");


my $cmp = NCM::Component::freeipa->new("freeipa");
my $cfg = get_config_for_profile("client");

=head2 Simple test

=cut

my $fqdn = $cmp->set_fqdn(config => $cfg);
my $tree = $cfg->getTree($cmp->prefix());
my $ipa;

$context = undef;

$cmp->set_fqdn(config => $cfg);
$ipa = $cmp->set_ipa_client($tree);
ok(! defined($ipa), "set_ipa_client returns undef if CAF::Kerberos get_context fails");
is_deeply($krb5->{ticket}, {keytab => '/etc/krb5.keytab'}, "Kerberos using correct ticket");
is_deeply($krb5->{principal}, {primary => 'host', instances => [$fqdn]}, "Kerberos using correct principal");

$context = 1;

set_file_contents('/tmp/quattor_nss-XXXX/cert_myhost.example.com_anick1.csr',
                  "-----BEGIN CERTIFICATE REQUEST-----\nCSRDATA\n-----END CERTIFICATE REQUEST-----");

# anick1 is not yet known
set_command_status('/usr/bin/certutil -d /etc/ipa/quattor/nssdb -L -a -n anick1', 1);

command_history_reset;
reset_caf_path;

$ipa = $cmp->set_ipa_client($tree);
ok($cmp->client($tree), "client returns success");
ok(command_history_ok([
    "/usr/sbin/ipa-getkeytab -s myhost.example.com -p someservice1/myhost.example.com -k /etc/super1.keytab -r\$",
    "/usr/sbin/ipa-getkeytab -s myhost.example.com -p someservice2/myhost.example.com -k /etc/super2.keytab\$",
    "/usr/bin/certutil -d /etc/ipa/quattor/nssdb -N -f /dev/null",
    "/usr/bin/certutil -d /etc/ipa/quattor/nssdb -A -n MY.REALM IPA CA -t CT,, -a -i /etc/ipa/ca.crt",
    "/usr/bin/certutil -d /etc/ipa/quattor/nssdb -L -a -n anick1",
    "/usr/bin/certutil -d /etc/ipa/quattor/nssdb -R -g 4096 -s CN=myhost.example.com,O=MY.REALM -z /tmp/quattor_nss-XXXX/random_anick1.data -a -o /tmp/quattor_nss-XXXX/cert_myhost.example.com_anick1.csr",
    "/usr/bin/certutil -d /etc/ipa/quattor/nssdb -A -n anick1 -t u,u,u -a -i /tmp/quattor_nss-XXXX/init_nss_anick1.crt",
    "/usr/bin/certutil -d /etc/ipa/quattor/nssdb -L -n anick1 -a -o /path/to/cert",
    "/usr/bin/pk12util -o /tmp/quattor_nss-XXXX/p12keys/key.p12 -n anick1 -d /etc/ipa/quattor/nssdb -W ",
    "/usr/bin/openssl pkcs12 -in /tmp/quattor_nss-XXXX/p12keys/key.p12 -out /path/to/key -nodes -password pass:",
]), "ipa-getkeytab and nss commands called");


my $fh = get_file('/tmp/quattor_nss-XXXX/init_nss_anick1.crt');
is("$fh", "CRTDATA\n", "certificate file with correct content");

diag explain $Test::Quattor::caf_path->{status};

is_deeply($Test::Quattor::caf_path->{status}, [
    [['/etc/super1.keytab'], {owner => 'root', group => 'root', mode => 0123}],
    [['/etc/super2.keytab'], {owner => 'root', group => 'superpower', mode => 0400}],
    [['/path/to/cert'], {owner => 'root', group => 'root', mode => 0444}], # default perm
    [['/path/to/key'], {owner => 'root', group => 'root', mode => 0400}], # default perm
    [['/etc/ipa/quattor/certs/host.pem'], {owner => 'root', group => 'superpowerssss', mode => 0444}], # hostcert cert
    [['/etc/ipa/quattor/keys/host.key'], {owner => 'root', group => 'superpowerssss', mode => 0400}], # hostcert key
], 'CAF::Path status called in keytabs');

diag explain $Test::Quattor::caf_path->{directory};

foreach my $dir (@{$Test::Quattor::caf_path->{directory}}) {
    if ($dir->[0]->[0] eq '/etc/ipa/quattor/nssdb') {
        is_deeply($dir,
                  [['/etc/ipa/quattor/nssdb'], {'group' => 'somegroup', 'mode' => 0400, 'owner' => 'root'}],
                  "nssdb dir created with proper permissions");
        last;
    }
}

# unmock JSON::XS for Cover
$mock_rpc::json->unmock_all();
done_testing();
