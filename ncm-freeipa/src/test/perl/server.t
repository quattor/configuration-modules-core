use strict;
use warnings;

use mock_rpc qw(server);
use Test::More;
use Test::Quattor qw(server);
use Test::MockModule;

use NCM::Component::freeipa;

my $mockk = Test::MockModule->new('CAF::Kerberos');
my $krb5;
my $context = 1;
$mockk->mock('get_context', sub {$krb5 = shift; return $context});


my $cmp = NCM::Component::freeipa->new("freeipa");
my $cfg = get_config_for_profile("server");
my $fqdn = $cmp->set_fqdn(config => $cfg);
my $tree;

=head2 Simple test

=cut

$tree = {primary => 'some.host'};
$cmp->set_ipa_client($tree);
ok($cmp->server($tree), 'server returns success with empty configtree');

=head2 actual test

=cut

$tree = $cfg->getTree($cmp->prefix());
$cmp->set_ipa_client($tree);

reset_POST_history;
ok($cmp->server($tree), 'server returns success');

# No dnszones found, adding them all
# 3: with autoreverse
# 2: no autoreverse / reverse
# 3: manual reverse
my $total_zones = 3+2+3;
is(scalar find_POST_history("dnszone_add"), $total_zones, "one dnszone_add per subnet to add");
ok(POST_history_ok([
   "dnszone_add subnet1.subdomain ",
   "dnszone_add 10.11.12.0/24 ",
   "dnszone_add 12.11.10.in-addr.arpa. ",

   "dnszone_add subnet2.subdomain ",
   "dnszone_add 10.11.13.0/24 ",

   "dnszone_add subnet3.subdomain ",
   "dnszone_add 10.11.14.0/24 ",
   "dnszone_add 15.11.10.in-addr.arpa. ",
]), "server dns POST");

my $total_hosts = 3;
is(scalar find_POST_history("host_add"), $total_hosts, "one host_add per host to add");
ok(POST_history_ok([
   "host_add host1.subnet1.subdomain ",
   "host_add host2.subnet2.subdomain ip_address=10.11.13.1,",
   "host_add host3.subnet3.subdomain ip_address=10.11.13.1,macaddress=aa:bb:cc:dd:ee:ff,",
]), "server host POST");

my $total_services = 4;
is(scalar find_POST_history('service_add \w+/\w+'), $total_services, "one service_add per service to add");
is(scalar find_POST_history('service_allow_create_keytab \w+/\w+ host=(serv|hyp)\d+'), $total_services,
   "one service_allow_create_keytab per service to add");
is(scalar find_POST_history('service_allow_retrieve_keytab \w+/\w+ host=(serv|hyp)\d+'), $total_services,
   "one service_allow_retrieve_keytab per service to add");
ok(POST_history_ok([
   "service_add HTTP/serv10 version",
   "service_allow_create_keytab HTTP/serv10 host=",
   "service_allow_retrieve_keytab HTTP/serv10 host=",
   "service_add HTTP/serv20 version",
   "service_allow_create_keytab HTTP/serv20 host=",
   "service_allow_retrieve_keytab HTTP/serv20 host=",
   "service_add libvirt/hyp100 version",
   "service_allow_create_keytab libvirt/hyp100 host=",
   "service_allow_retrieve_keytab libvirt/hyp100 host=",
   "service_add libvirt/hyp300 version",
   "service_allow_create_keytab libvirt/hyp300 host=",
   "service_allow_retrieve_keytab libvirt/hyp300 host=",
]), "server service POST");

my $total_users = 2;
my $total_groups = 2;
my $total_groups_w_members = 2;
is(scalar find_POST_history('group_add \w+'), $total_groups,
   "one group_add per group to add");
is(scalar find_POST_history('user_add \w+'), $total_users,
   "one user_add per user to add");
is(scalar find_POST_history('group_add_member \w+ user=\w+'), $total_groups_w_members,
   "one group_add_member per group w members to add");

ok(POST_history_ok([
   "group_add mygroup1 gidnumber=123456,version",
   "group_add mygroup2 gidnumber=234567,version",
   "user_add user1 gidnumber=123456,givenname=first1,ipasshpubkey=abc,def,sn=last1,uidnumber=1245,version",
   "user_add user2 givenname=first2,ipasshpubkey=xyz,loginshell=/bin/bash,sn=last2,uidnumber=2356,version",
   "group_add_member mygroup1 user=a,b,c,version",
   "group_add_member mygroup2 user=d,e,f,version",
]), "server users/groups POST");

# unmock JSON::XS for Cover
$mock_rpc::json->unmock_all();
done_testing();
