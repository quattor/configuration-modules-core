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
$cmp->use_cluster();
my $t = $cfg->getElement($PATH)->getTree();
my $cluster = $t->{clusters}->{ceph};
my $quath = $cluster->{config};
#diag explain $quath;
my $cceph =  {
   'fsid' => 'a94f906-ff68-487d-8193-23ad04c1b5c4', #wrong fsid
   'mon_initial_members' => 'ceph001,ceph002,ceph003'
 };
#diag explain $cceph;
my $output = $cmp->ceph_quattor_cmp('cfg', $quath, $cceph);
ok(!$output, 'ceph quattor cmp for cfg');

$cmp->{comp} = 1;
$cceph =  {
   'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4', #correct fsid
   'mon_initial_members' => 'ceph001,ceph002,ceph003'
 };
$output = $cmp->ceph_quattor_cmp('cfg', $quath, $cceph);
ok($output, 'ceph quattor cmp for cfg');
is($cmp->{comp},1,'config the same');

$cmp->{comp} = 1;
$cceph =  {
   'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4', #correct fsid
   'mon_initial_members' => 'ceph001,ceph002', #different
 };
$output = $cmp->ceph_quattor_cmp('cfg', $quath, $cceph);
ok($output, 'ceph quattor cmp for cfg');
is($cmp->{comp},-1,'config differs');

$cmp->{comp} = 1;
$cceph =  {
   'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4', #correct fsid
   'mon_initial_members' => 'ceph001,ceph002,ceph003',
   'blaaa' => 'bla'
 };
$output = $cmp->ceph_quattor_cmp('cfg', $quath, $cceph);
ok($output, 'ceph quattor cmp for cfg');
is($cmp->{comp},-1,'config the same');

$cmp->{comp} = 1;
$cceph =  {
   'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4', #correct fsid
 };
$output = $cmp->ceph_quattor_cmp('cfg', $quath, $cceph);
ok($output, 'ceph quattor cmp for cfg');
is($cmp->{comp},-1,'config the same');

done_testing();
