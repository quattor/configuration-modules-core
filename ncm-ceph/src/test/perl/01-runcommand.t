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

set_desired_output("ceph -f json mon dump --cluster ceph", $data::MONJSON);

my @fullcmd = qw(ceph -f json mon dump --cluster ceph);
my @cephcmd = qw(mon dump);

my $wr = $cmp->use_cluster('bla');
ok(!$wr, 'non default cluster not implemented');
my $de =  $cmp->use_cluster();
ok($de, 'default cluster');
my $output = $cmp->run_command(\@fullcmd);
is($output,$data::MONJSON, 'running ceph command');

my $outputc = $cmp->run_ceph_command(\@cephcmd);
is($outputc,$data::MONJSON,'running ceph command');

my $fsid = $cmp->get_fsid();
is($fsid,$data::FSID, 'retrieving fsid');

my $mons = $cmp->mon_hash();
cmp_deeply($mons,\%data::MONS, 'build monitor hash');
diag explain $mons;
#my $osds = $cmp->osd_hash();
#TODO implement
#ok($osds, 'build osd hash');
 
done_testing();
