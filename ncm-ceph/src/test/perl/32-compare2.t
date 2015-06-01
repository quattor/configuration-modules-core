# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the add osd function with max_add_osd_failures_per_host = 1


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(basic_cluster);
use NCM::Component::ceph;
use CAF::Object;
use data;
use Storable qw(dclone);
use Readonly;

$CAF::Object::NoAction = 1;
my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');
my $mockc = Test::MockModule->new('NCM::Component::Ceph::commands');
my $mock = Test::MockModule->new('NCM::Component::Ceph::daemon');
my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
$cmp->use_cluster();
$mockc->mock('test_host_connection', 0 );

my $quatin_l = dclone(\%data::QUATIN);
my $structures = $cmp->compare_conf($quatin_l, \%data::CEPHIN, \%data::MAPPING, { max_add_osd_failures_per_host => 0 });
ok($structures, "No (OSD) failures");
ok($structures->{deployd}->{ceph002}->{osds}->{"ceph002:/var/lib/ceph/osd/sdc"}, "OSD is to be deployed");

$mock->mock('prep_osd', 0 );
$quatin_l = dclone(\%data::QUATIN);
$structures = $cmp->compare_conf($quatin_l, \%data::CEPHIN, \%data::MAPPING, { max_add_osd_failures_per_host => 0 });
ok(!$structures, "OSD failures not tolerated");

$quatin_l = dclone(\%data::QUATIN);
$structures = $cmp->compare_conf($quatin_l, \%data::CEPHIN, \%data::MAPPING, { max_add_osd_failures_per_host => 1 });
ok($structures, "1 OSD failure per host tolerated");
ok(!$structures->{deployd}->{ceph002}->{osds}->{"ceph002:/var/lib/ceph/osd/sdc"}, "OSD is not going to be deployed");
is($quatin_l->{ceph002}->{osds}->{"ceph002:/var/lib/ceph/osd/sdc"}->{crush_ignore}, 1, "OSD is not included in crushmap");
done_testing();
