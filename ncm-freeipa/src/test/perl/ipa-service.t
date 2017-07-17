use strict;
use warnings;

use mock_rpc qw(service);

use Test::Quattor;
use Test::Quattor::Object;
use Test::More;

use NCM::Component::FreeIPA::Client;

my $obj = Test::Quattor::Object->new();
my $c = NCM::Component::FreeIPA::Client->new("host.example.com", log => $obj);

isa_ok($c, 'NCM::Component::FreeIPA::Client',
       "NCM::Component::FreeIPA::Client instance returned");
isa_ok($c, 'NCM::Component::FreeIPA::Service',
       "NCM::Component::FreeIPA::Client is a NCM::Component::FreeIPA::Service instance");

my @cmds;

=head2 add

=cut

reset_POST_history;
ok(! defined($c->add_service('existing')), "add_host returns undef when service can be found");
ok(POST_history_ok(["service_add existing"], ["service_find"]), "service_add called, no service_find called");

reset_POST_history;
is_deeply($c->add_service('missing'), {okunittest => 1},
          "missing service added");
ok(POST_history_ok(["service_add missing version="], ["service_find"]),
   "service_add called for missing");

=head2 add_hostservice

=cut

$c->{id} = 1;

reset_POST_history;
is_deeply($c->add_service_host('myservice', 'myhost.domain'), {okunittest => 2}, "add_service_host returns expected value");
ok(POST_history_ok([
   "service_add myservice/myhost.domain",
   "service_allow_create_keytab myservice/myhost.domain host=myhost.*",
   "service_allow_retrieve_keytab myservice/myhost.domain host=myhost.*",
]), "service_add and service_allow_(create|retrieve)_keytab for host called");

=head2 service_has_keytab

=cut

$c->{id} = 2;
reset_POST_history;
is($c->service_has_keytab('SERVICE/myhost.domain'), 1, "service has keytab");
ok(POST_history_ok([
   "service_show SERVICE/myhost.domain version=.*",
]), "service_show for SERVICE/myhost called");

# unmock JSON::XS for Cover
$mock_rpc::json->unmock_all();
done_testing;
