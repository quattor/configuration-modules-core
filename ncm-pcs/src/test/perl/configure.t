use strict;
use warnings;

use Test::Quattor qw(simple);
use Test::More;
use Test::Quattor::Object;
use NCM::Component::pcs;

my $obj = Test::Quattor::Object->new();

my $cmp = NCM::Component::pcs->new("pcs", $obj);
my $cfg = get_config_for_profile("simple");
my $tree = $cfg->getTree($cmp->prefix);

use helper;

=head2 _short

=cut

is_deeply([NCM::Component::pcs::_short("a", "b.b2", "c.c2.c3")],
          [qw(a b c)], "_short return args as short hostnames");
is_deeply([NCM::Component::pcs::_short(["a", "b.b2", "c.c2.c3"])],
          [qw(a b c)], "_short return arrayref arg as short hostnames");

=head2 has_token

=cut

ok(!$cmp->has_tokens([qw(a b.b c.c.c)]), "no tokens found");
is($obj->{LOGLATEST}->{ERROR},
   "No tokens /var/lib/pcsd/tokens found. Create them with command \"pcs cluster auth a b c -u hacluster -p \'haclusterpassword\'\"",
   "reported error on missing tokens contains command to add auth nodes");

ok(!defined $cmp->Configure($cfg), "Configure returns undef with missing tokens");
like($obj->{LOGLATEST}->{ERROR}, qr{cluster auth nodea nodeb},
     "reported error on missing tokens contains command to add auth nodes from configure");

set_file_contents("/var/lib/pcsd/tokens", "");

ok($cmp->has_tokens([qw(a b c)]), "tokens found");

=head2 setup

=cut


my $statuscmd = 'pcs cluster status';
my $setupcmd = 'pcs cluster setup --name simple nodea nodeb';
my $startcmd = 'pcs cluster start nodea nodeb';
my $statusnodes = 'pcs status nodes both';
set_command_status($setupcmd, 1);

set_output('cluster_notok');
set_output('status_nodes');

command_history_reset();
ok(!defined $cmp->Configure($cfg), "Configure returns undef with missing cluster failed setup");
ok(command_history_ok([$statuscmd, $startcmd, $statuscmd, $setupcmd]),
   "pcs cluster status, start, status and setup called");

command_history_reset();
set_command_status($setupcmd, 0);
ok(!defined($cmp->setup($tree->{cluster})), "setup returns undef with succesfull cluster setup and still failing status");
ok(command_history_ok([$statuscmd, $startcmd, $statuscmd, $setupcmd, $statuscmd]),
   "pcs cluster status, start, status, setup and status called");

=head2 nodes

=cut

set_output('status_nodes');
ok(!defined $cmp->nodes(['nodea.a']),
   "nodes returns undef when unknown nodes are present");
ok(!defined $cmp->nodes(['nodea.a', 'nodeb.b', 'nodec']),
   "nodes returns undef when nodes are missing");
ok($cmp->nodes(['nodea.a', 'nodeb.b']),
   "nodes returns ok when nodes as expected");

set_output('status_nodes_maint');
ok(! defined $cmp->nodes(['nodea.a', 'nodeb.b']),
   "nodes returns undef when node is in maintenance (i.e. not online)");

set_output('status_nodes_remote');
ok(! defined $cmp->nodes(['nodea.a', 'nodeb.b']),
   "nodes returns undef when a remote node is found");

# last, reset ok node state
set_output('status_nodes');


=head2 Configure

=cut

set_output('cluster_ok');
command_history_reset();
ok($cmp->Configure($cfg), "setup returns ok with succesfull cluster status");
ok(command_history_ok([$statuscmd, $statusnodes], ['start', 'setup']),
   "pcs cluster and nodes status called, no setup or start");


ok($cmp->Configure($cfg), "Configure returns ok");


done_testing;
