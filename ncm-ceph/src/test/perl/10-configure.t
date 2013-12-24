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

set_desired_output("ceph -f json mon dump --cluster ceph", 
    $data::MONJSON);
set_desired_output("ceph -f json quorum_status --cluster ceph", $data::STATE);

$cmp->use_cluster();
my $fsid = $cmp->get_fsid();
my $mons = $cmp->mon_hash();

my $t = $cfg->getElement($PATH)->getTree();
my $cluster = $t->{clusters}->{ceph};
my $id = $cluster->{config}->{fsid};
#diag explain $cluster;

my $type = 'mon';
my $cephh = $cmp->mon_hash();
my $quath = $cluster->{monitors};

$cmp->init_commands();
my $outputmon = $cmp->process_mons($quath);
ok($outputmon, 'ceph quattor cmp for mon');

cmp_deeply($cmp->{deploy_cmds}, \@data::ADDMON, 'deploy commands prepared');

my $dodeploy = $cmp->do_deploy();
ok($dodeploy, 'try running the commands');

cmp_deeply($cmp->{deploy_cmds},[],'deploy commands has been run');
cmp_deeply($cmp->{man_cmds}, \@data::DELMON, 'commands to be run manually');

#my $output = $cmp->Configure($cfg);
#ok($output, 'Configure ');
done_testing();
