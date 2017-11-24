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
set_command_status($statuscmd, 1);
set_command_status($setupcmd, 1);
command_history_reset();
ok(!defined $cmp->Configure($cfg), "Configure returns undef with missing cluster failed setup");
ok(command_history_ok([$statuscmd, $setupcmd]), "pcs cluster status and setup called");

set_command_status($setupcmd, 0);
ok($cmp->setup($tree->{cluster}), "setup returns ok with succesfull cluster setup");

set_command_status($statuscmd, 0);
command_history_reset();
ok($cmp->Configure($cfg), "setup returns ok with succesfull cluster status");
ok(command_history_ok([$statuscmd], ['setup']), "pcs cluster status called, no setup");


ok($cmp->Configure($cfg), "Configure returns ok");


done_testing;
