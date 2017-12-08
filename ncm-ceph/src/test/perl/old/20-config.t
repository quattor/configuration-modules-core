# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the configuration of the ceph.conf file


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
$cmp->use_cluster();
my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
my $quath = $cluster->{config};
#diag explain $quath;
my $cceph =  {
   'fsid' => 'a94f906-ff68-487d-8193-23ad04c1b5c4', #wrong fsid
   'mon_initial_members' => 'ceph001, ceph002, ceph003'
 };
#diag explain $cceph;
my $output = $cmp->check_immutables('host',['fsid'], $quath, $cceph);
ok(!$output, 'ceph quattor cmp for cfg');

$cceph =  {
   'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4', #correct fsid
   'mon_initial_members' => 'ceph001, ceph002, ceph003'
 };
$output = $cmp->compare_config('cfg','key', $quath, $cceph);
ok($output, 'ceph quattor cmp for cfg');
ok(!%{$output},'config the same');

$cceph =  {
   'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4', #correct fsid
   'mon_initial_members' => 'ceph001, ceph002', #different
 };
$output = $cmp->compare_config('cfg','key', $quath, $cceph);
ok($output, 'ceph quattor cmp for cfg');
ok(%{$output},'config differs');

$cceph =  {
   'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4', #correct fsid
   'mon_initial_members' => 'ceph001, ceph002, ceph003',
   'blaaa' => 'bla',
   'foo' => 'bar'
 };
$output = $cmp->compare_config('cfg','key', $quath, $cceph);
ok($output, 'ceph config has attributes not in quattor');
ok(!%{$output}, 'ceph config has attributes not in quattor');

$cceph =  {
   'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4', #correct fsid
 };
$output = $cmp->compare_config('cfg','key', $quath, $cceph);
ok($output, 'ceph quattor cmp for cfg');
ok(%{$output},'config differs');

done_testing();
