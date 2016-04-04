use strict;
use warnings;

use mock_rpc qw(dns);

use Test::Quattor;
use Test::More;

use NCM::Component::FreeIPA::Client;

my $c = NCM::Component::FreeIPA::Client->new("host.example.com");

isa_ok($c, 'NCM::Component::FreeIPA::Client',
       "NCM::Component::FreeIPA::Client instance returned");
isa_ok($c, 'NCM::Component::FreeIPA::DNS',
       "NCM::Component::FreeIPA::Client is a NCM::Component::FreeIPA::DNS instance");

=head2 add existing zone

=cut

reset_POST_history;
# default single result is success, so the find_one finds one
ok(! defined($c->add_dnszone("x.y.z")),
   "add_dnszone returns undef on existing zone");
ok(! find_POST_history('dnszone_add.*x.y.z'),
   'no dnszone_add for x.y.z');

=head2 add non-existing zone

=cut

reset_POST_history;
is_deeply($c->add_dnszone("a.b.c.d"), {okunittest=>1},
          "Added dnszone a.b.c.d");
ok(POST_history_ok(["dnszone_find.*a.b.c.d", "dnszone_add.*a.b.c.d"]),
   "find and add called for dnszone a.b.c.d");


done_testing();
