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

my $t = $cfg->getElement($PATH)->getTree();
my $cluster = $t->{clusters}->{ceph};

$cmp->use_cluster();
$cmp->{is_deploy} = 1;
$cmp->{hostname} = 'ceph001';
my $admin = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph admin ceph001";
my $gather1 = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph gatherkeys ceph001";
my $gather2 = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph gatherkeys ceph002";
my $gather3 = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph gatherkeys ceph003";
my $config2 = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph config pull ceph002";
my @gathers = ($gather1, $gather2, $gather3);
set_desired_output("/usr/bin/ceph -f json status --cluster ceph", $data::STATE);

# Already working cluster
#set_desired_output($admin,'');
set_command_status($admin,0);
set_desired_err($admin,'');

$cmp->init_commands();
my $clustercheck= $cmp->cluster_ready_check($cluster->{config}->{mon_initial_members});
ok($clustercheck, 'cluster is ready');
my $cmd = get_command($admin);
ok(defined($cmd), "admin command invoked");
foreach my $gcmd (@gathers) {
    $cmd = get_command($gcmd);
    ok(!defined($cmd), "cluster already set up: gather was not invoked");
}
$cmd = get_command($config2);
ok(!defined($cmd), "cluster already set up: pull config was not invoked to ceph002");

# Totally new cluster
#set_desired_output($admin,'');
set_command_status($admin,1);
#set_desired_error($admin,'');
foreach my $gcmd (@gathers) {
    set_command_status($gcmd,1);
    set_desired_err($gcmd,'');
}
$cmp->init_commands();
$clustercheck= $cmp->cluster_ready_check($cluster->{config}->{mon_initial_members});
foreach my $gcmd (@gathers) {
    $cmd = get_command($gcmd);
    ok(defined($cmd), "no cluster: gather had been tried");
}
$cmd = get_command($config2);
ok(!defined($cmd), "new cluster manual: pull config was not invoked to ceph002");
#diag explain $cmp->{man_cmds};

# Only ceph002 already configured

set_command_status($gather2,0);
$clustercheck= $cmp->cluster_ready_check($cluster->{config}->{mon_initial_members});
$cmd = get_command($config2);
ok(defined($cmd), "pull config was invoked to ceph002 (been configured)");

done_testing();
