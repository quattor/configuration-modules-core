use strict;
use warnings;

use mock_rpc qw(cert);

use Test::Quattor;
use Test::More;

use NCM::Component::FreeIPA::Client;

my $c = NCM::Component::FreeIPA::Client->new("host.example.com");

isa_ok($c, 'NCM::Component::FreeIPA::Client',
       "NCM::Component::FreeIPA::Client instance returned");
isa_ok($c, 'NCM::Component::FreeIPA::Cert',
       "NCM::Component::FreeIPA::Client is a NCM::Component::FreeIPA::Cert instance");

=head2 make certificate request

=cut

reset_POST_history;
is_deeply($c->request_cert("/path/to/req.csr", 'host/myhost.mydomain@EXAMPLE.COM'),
          {okunittest=>1}, "Made cert request");
ok(POST_history_ok(['cert_request /path/to/req.csr principal=host/myhost.mydomain@EXAMPLE.COM,version']),
   "certificate request made");

=head2 show

=cut

reset_POST_history;
is_deeply($c->get_cert(123, '/path/to/cert.crt'),
          {okunittest=>1}, "Get certificate");
ok(POST_history_ok(['cert_show 123 out=/path/to/cert.crt,version']),
   "get_cert is certificate show made");



done_testing();
