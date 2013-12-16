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

set_desired_output("ceph -f json mon dump --cluster ceph 2> /dev/null", $data::MONJSON);

my @fullcmd = qw(ceph -f json mon dump --cluster ceph 2> /dev/null);
my @cephcmd = qw(mon dump);

$cmp->use_cluster();
my $output = $cmp->run_command(\@fullcmd);
is($output,$data::MONJSON, 'running ceph command');

my $outputc = $cmp->run_ceph_command(\@cephcmd);
is($outputc,$data::MONJSON,'running ceph command');

my $fsid = $cmp->get_fsid();
is($fsid,$data::FSID, 'comparing fsid');
diag $fsid;
my $mons = $cmp->mon_hash();
cmp_deeply($mons,\%data::MONS, 'comparing monitor hashes');

done_testing();
