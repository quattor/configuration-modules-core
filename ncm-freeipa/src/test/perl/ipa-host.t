use strict;
use warnings;

use mock_rpc qw(host);

use Test::Quattor;
use Test::Quattor::Object;
use Test::More;

use NCM::Component::FreeIPA::Client;

my $obj = Test::Quattor::Object->new();
my $c = NCM::Component::FreeIPA::Client->new("host.example.com", log => $obj);

isa_ok($c, 'NCM::Component::FreeIPA::Client',
       "NCM::Component::FreeIPA::Client instance returned");
isa_ok($c, 'NCM::Component::FreeIPA::Host',
       "NCM::Component::FreeIPA::Client is a NCM::Component::FreeIPA::Host instance");

my @cmds;

=head2 add

=cut

reset_POST_history;
ok(! defined($c->add_host('host.domain')), "add_host returns undef when host can be found");
ok(POST_history_ok(["host_add host.domain"], ["host_find"]), "host_add called, no host_find called");

reset_POST_history;
is_deeply($c->add_host('missing.domain'), {okunittest => 1},
          "missing.domain host added");
ok(POST_history_ok(["host_add missing.domain version="],["host_find .*missing.domain"]),
   "host_add called for missing.domain, no ip/mac");

reset_POST_history;
is_deeply($c->add_host('missing.domain', ip_address => '1.2.3.4', macaddress => ['aa:bb:cc:dd:ee:ff']),
          {okunittest => 1},
          "missing.domain host added");
ok(POST_history_ok(["host_add missing.domain ip_address=1.2.3.4,macaddress=aa:bb:cc:dd:ee:ff,version="]),
   "host_add called for missing.domain with ip/mac");

=head2 password

=cut

$c->{id} = 1;

reset_POST_history;
ok(! defined($c->host_passwd('missing.domain')), "host_passwd returns undef when host cannot be found");
ok(POST_history_ok(["host_mod missing.domain"]), "host_mod called, NotFound error");

reset_POST_history;
is($c->host_passwd('host.domain'), 'supersecret', "host_passwd returns random password");
ok(POST_history_ok(["host_mod host.domain random=1"]), "host_mod called");


=head2 disable

=cut

reset_POST_history;
is_deeply($c->disable_host('host.domain'), {okunittest => 1},
          "host.domain host disabled");
ok(POST_history_ok(["host_disable host.domain version="]),
   "host_disable called for host.domain");

=head2 remove

=cut

reset_POST_history;
is_deeply($c->remove_host('host.domain'), {okunittest => 1},
          "host.domain host removed");
ok(POST_history_ok(["host_del host.domain updatedns=1,version="]),
   "host_del called for host.domain");


# unmock JSON::XS for Cover
$mock_rpc::json->unmock_all();
done_testing();
