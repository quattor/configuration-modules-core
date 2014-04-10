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
use Test::Quattor qw(basic_crushmap);
use Test::MockModule;
use NCM::Component::ceph;
use CAF::Object;
use crushdata;
use Readonly;
Readonly::Scalar my $PATH => '/software/components/ceph';


$CAF::Object::NoAction = 1;
my $mock = Test::MockModule->new('NCM::Component::ceph');

my $cfg = get_config_for_profile('basic_crushmap');
my $cmp = NCM::Component::ceph->new('ceph');

set_desired_output("/usr/bin/ceph -f json --cluster ceph osd crush dump", $crushdata::CRUSHMAP_01);

my $t = $cfg->getElement($PATH)->getTree();
my $cluster = $t->{clusters}->{ceph};

$cmp->use_cluster();
my $crush = $cluster->{crushmap};
$cmp->flatten_osds($cluster->{osdhosts});
$cmp->quat_crush($crush, $cluster->{osdhosts});
cmp_deeply($crush, \%crushdata::QUATMAP, 'hash from quattor built');
$cmp->{qtmp} = '/tmp';
my $chash = $cmp->ceph_crush();
cmp_deeply($chash, \%crushdata::CEPHMAP, 'hash from ceph built');
$crush->{devices} = $chash->{devices}; # resolved on live system
$cmp->cmp_crush($chash, $crush);
cmp_deeply($crush, \%crushdata::CMPMAP, 'hash after compare and ids built');
my $str = "# begin crush map\n";
ok($cmp->template()->process('ceph/crush.tt', $crush, \$str),
   "Template successfully rendered");
# Full crushmap test, but device items not completely mocked (have all id 0)
is($str,$crushdata::WRITEMAP, 'written crushmap ok');
is($cmp->template()->error(), "", "No errors in rendering the template");

done_testing();
