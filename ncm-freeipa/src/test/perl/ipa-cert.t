use strict;
use warnings;

use mock_rpc qw(cert);

use CAF::Object;
use Test::Quattor;
use Test::More;

$CAF::Object::NoAction = 1;

use NCM::Component::FreeIPA::Client;

my $c = NCM::Component::FreeIPA::Client->new("host.example.com");

isa_ok($c, 'NCM::Component::FreeIPA::Client',
       "NCM::Component::FreeIPA::Client instance returned");
isa_ok($c, 'NCM::Component::FreeIPA::Cert',
       "NCM::Component::FreeIPA::Client is a NCM::Component::FreeIPA::Cert instance");

=head2 make certificate request

=cut

# Not a valid csr, but 2 different start/stop for regexp test
my $CSRDATA = <<EOF;

garbage

-----BEGIN NEW CERTIFICATE REQUEST-----
CSRREQUEST
-----END CERTIFICATE REQUEST-----

    more garbage

EOF

set_file_contents('/path/to/req.csr', $CSRDATA);

reset_POST_history;
is_deeply($c->request_cert("/path/to/req.csr", 'host/myhost.mydomain@EXAMPLE.COM'),
          {okunittest=>1}, "Made cert request");
ok(POST_history_ok(['cert_request -----BEGIN NEW CERTIFICATE REQUEST-----\nCSRREQUEST\n-----END CERTIFICATE REQUEST----- principal=host/myhost.mydomain@EXAMPLE.COM,version']),
   "certificate request made");

=head2 show

=cut

reset_POST_history;
is_deeply($c->get_cert(123, '/path/to/cert.crt'),
          {certificate => 'CERTDATA'}, "Get certificate");
ok(POST_history_ok(['cert_show 123 version']),
   "get_cert is certificate show made");

my $fh = get_file('/path/to/cert.crt');
is("$fh", "CERTDATA\n", "get_cert writes file");


# unmock JSON::XS for Cover
$mock_rpc::json->unmock_all();
done_testing();
