use strict;
use warnings;

use mock_rpc qw(user);

use Test::Quattor;
use Test::Quattor::Object;
use Test::More;

use NCM::Component::FreeIPA::Client;

my $obj = Test::Quattor::Object->new();
my $c = NCM::Component::FreeIPA::Client->new("host.example.com", log => $obj);

isa_ok($c, 'NCM::Component::FreeIPA::Client',
       "NCM::Component::FreeIPA::Client instance returned");
isa_ok($c, 'NCM::Component::FreeIPA::User',
       "NCM::Component::FreeIPA::Client is a NCM::Component::FreeIPA::User instance");

my @cmds;

=head2 add

=cut

reset_POST_history;
ok(! defined($c->add_user('user1', givenname=> 'first', sn => 'last')), "add_user returns undef when user can be found");
ok(POST_history_ok(["user_add user1 givenname=first,sn=last,version="], ["user_find"]), "user_add called, no user_find called");

reset_POST_history;
is_deeply($c->add_user('missing1', givenname=> 'first', sn => 'last'), {okunittest => 1},
          "missing1 user added");
ok(POST_history_ok(["user_add missing1 givenname=first,sn=last,version="],["user_find .*missing1"]),
   "user_add called for missing1, no ip/mac");

reset_POST_history;
is_deeply($c->add_user('missing1', givenname=> 'first', sn => 'last'),
          {okunittest => 1},
          "missing1 user added");
ok(POST_history_ok(["user_add missing1 givenname=first,sn=last,version="]),
   "user_add called for missing1");

=head2 password

=cut

$c->{id} = 1;

reset_POST_history;
ok(! defined($c->user_passwd('missing1')), "user_passwd returns undef when user cannot be found");
ok(POST_history_ok(["user_mod missing1"]), "user_mod called, NotFound error");

reset_POST_history;
is($c->user_passwd('user1'), 'supersecret', "user_passwd returns random password");
ok(POST_history_ok(["user_mod user1 random=1"]), "user_mod called");


=head2 disable

=cut

reset_POST_history;
is_deeply($c->disable_user('user1'), {okunittest => 1},
          "user1 user disabled");
ok(POST_history_ok(["user_disable user1 version="]),
   "user_disable called for user1");

=head2 remove

=cut

reset_POST_history;
is_deeply($c->remove_user('user1'), {okunittest => 1},
          "user1 user removed");
ok(POST_history_ok(["user_del user1 preserve=1,version="]),
   "user_del called for user1");


# unmock JSON::XS for Cover
$mock_rpc::json->unmock_all();
done_testing();
