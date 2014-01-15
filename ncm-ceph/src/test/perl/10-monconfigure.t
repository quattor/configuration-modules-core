# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 run Ceph command test
Test the runs of ceph commands


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(basic_cluster);
use Test::MockModule;
use NCM::Component::ceph;
use CAF::Object;
use data;
use Readonly;
Readonly::Scalar my $PATH => '/software/components/ceph';


$CAF::Object::NoAction = 1;
my $mock = Test::MockModule->new('NCM::Component::ceph');

my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');

set_desired_output("/usr/bin/ceph -f json mon dump --cluster ceph", 
    $data::MONJSON);
set_desired_output("/usr/bin/ceph -f json quorum_status --cluster ceph", $data::STATE);

$cmp->use_cluster();
$cmp->{cfgfile} = 'tmpfile';
my $fsid = $cmp->get_fsid();
my $mons = $cmp->mon_hash();

my $t = $cfg->getElement($PATH)->getTree();
my $cluster = $t->{clusters}->{ceph};
my $id = $cluster->{config}->{fsid};

my $type = 'mon';
my $cephh = $cmp->mon_hash();
my $quath = $cluster->{monitors};

$cmp->init_commands();
$cmp->{hostname} = 'ceph001';
#Main monitor comparison function:
my $outputmon = $cmp->process_mons($quath);
ok($outputmon, 'ceph quattor cmp for mon');

cmp_deeply($cmp->{deploy_cmds}, \@data::ADDMON, 'deploy commands prepared');
diag explain @{$cmp->{daemon_cmds}};

cmp_deeply($cmp->{man_cmds}, \@data::DELMON, 'commands to be run manually');
$cmp->{is_deploy} = 'true';
my $dodeploy = $cmp->do_deploy();
ok($dodeploy, 'try running the commands');

my $deployaddstring = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph mon create ceph002";
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

cmp_deeply($cmp->{deploy_cmds},[],'deploy commands are cleared');

done_testing();
