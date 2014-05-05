# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the configuration of the monitor


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(basic_cluster);
use NCM::Component::ceph;
use CAF::Object;
use data;
use Readonly;


$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');

set_desired_output("/usr/bin/ceph -f json --cluster ceph mon dump", 
    $data::MONJSON);
set_desired_output("/usr/bin/ceph -f json --cluster ceph quorum_status", $data::STATE);

$cmp->use_cluster();
$cmp->{clname} = 'ceph';
$cmp->{cfgfile} = 'tmpfile';
my $mons = $cmp->mon_hash();

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
my $id = $cluster->{config}->{fsid};

my $type = 'mon';
my $cephh = $cmp->mon_hash();
my $quath = $cluster->{monitors};

my $cmdh = $cmp->init_commands();
$cmp->{hostname} = 'ceph001';
#Main monitor comparison function:
my $outputmon = $cmp->process_mons($quath, $cmdh);
ok($outputmon, 'ceph quattor cmp for mon');

cmp_deeply($cmdh->{deploy_cmds}, \@data::ADDMON, 'deploy commands prepared');
diag explain @{$cmdh->{daemon_cmds}};

cmp_deeply($cmdh->{man_cmds}, \@data::DELMON, 'commands to be run manually');
my $dodeploy = $cmp->do_deploy(1, $cmdh);
ok($dodeploy, 'try running the commands');

my $deployaddstring = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph mon create ceph002.cubone.os";
my $cmd = get_command($deployaddstring);
ok(defined($cmd), "mon add was invoked");

$deployaddstring = "/etc/init.d/ceph start mon.ceph003";
$cmd = get_command($deployaddstring);
ok(!defined($cmd), "mon3 start invoked");
$deployaddstring = "/etc/init.d/ceph stop mon.ceph003";
$cmd = get_command($deployaddstring);
ok(!defined($cmd), "mon3 stop must not be invoked");
$deployaddstring = "/etc/init.d/ceph start mon.ceph001";
$cmd = get_command($deployaddstring);
ok(!defined($cmd), "mon1 stop must not be invoked");

cmp_deeply($cmdh->{deploy_cmds},[],'deploy commands are cleared');

done_testing();
