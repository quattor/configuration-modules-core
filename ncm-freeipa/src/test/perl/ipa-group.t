use strict;
use warnings;

use mock_rpc qw(group);

use Test::Quattor;
use Test::More;

use NCM::Component::FreeIPA::Client;

my $c = NCM::Component::FreeIPA::Client->new("host.example.com");

isa_ok($c, 'NCM::Component::FreeIPA::Client',
       "NCM::Component::FreeIPA::Client instance returned");
isa_ok($c, 'NCM::Component::FreeIPA::Group',
       "NCM::Component::FreeIPA::Client is a NCM::Component::FreeIPA::Group instance");

=head2 add group

=cut

reset_POST_history;
# default single result is success, so the find_one finds one
ok(! defined($c->add_group("existing")),
   "add_group returns undef on existing group");
ok(POST_history_ok(["group_add.*existing"], ["group_find.*existing"]),
   "add and no find called for group existing");

=head2 add non-existing zone

=cut

reset_POST_history;
is_deeply($c->add_group("missing"), {okunittest=>1},
          "Added group missing");
ok(POST_history_ok(["group_add.*missing"], ["group_find.*missing"]),
   "add and no find called for group missing");

=head2 add group member

=cut

reset_POST_history;
is_deeply($c->add_group_member("missing", user => [qw(a b c)]), {okunittest=>1},
          "Added group members to missing");
ok(POST_history_ok(["group_add_member missing user=a,b,c,vers"]),
   "added group members to group missing");


# unmock JSON::XS for Cover
$mock_rpc::json->unmock_all();
done_testing();
