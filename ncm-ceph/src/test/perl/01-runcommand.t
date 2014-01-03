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
use Test::Quattor;
use NCM::Component::ceph;
use CAF::Object;
use data;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::ceph->new("ceph");

set_desired_output("/usr/bin/ceph -f json mon dump --cluster ceph", $data::MONJSON);
my @fullcmd = qw(/usr/bin/ceph -f json mon dump --cluster ceph);
my @cephcmd = qw(mon dump);
set_desired_output("/usr/bin/ceph -f json quorum_status --cluster ceph", $data::STATE);
my $deploycmdstring = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph mon create ceph002";
my @cdepcmd = qw(mon create ceph002);
set_desired_output($deploycmdstring, "Monitor ceph002 created");

my $wr = $cmp->use_cluster('bla');
ok(!$wr, 'non default cluster not implemented');
my $de =  $cmp->use_cluster();
ok($de, 'default cluster');
my $output = $cmp->run_command(\@fullcmd);
is($output,$data::MONJSON, 'running ceph command');

$output = $cmp->run_ceph_command(\@cephcmd);
is($output,$data::MONJSON,'running ceph command');

$output = $cmp->run_ceph_deploy_command(\@cdepcmd);
is($output,"Monitor ceph002 created",'ceph-deploy command');

my $fsid = $cmp->get_fsid();
is($fsid,$data::FSID, 'retrieving fsid');

my $mons = $cmp->mon_hash();
cmp_deeply($mons,\%data::MONS, 'build monitor hash');
#diag explain $mons;
#my $osds = $cmp->osd_hash();
#TODO implement
#ok($osds, 'build osd hash');
 
done_testing();
