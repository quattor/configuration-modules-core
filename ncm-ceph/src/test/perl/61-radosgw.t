# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the build of the quattor configuration hash for a radosgw


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(basic_radosgw);
use NCM::Component::ceph;
use CAF::Object;
use data;
use Readonly;

$CAF::Object::NoAction = 1;
my $cfg = get_config_for_profile('basic_radosgw');
my $cmp = NCM::Component::ceph->new('ceph');

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};

my $master = $cmp->get_quat_conf($cluster);
cmp_deeply($master, \%data::QUATMAPGW, 'Quattor config hash');
my $mockc = Test::MockModule->new('NCM::Component::Ceph::commands');
$cmp->use_cluster();
$mockc->mock('test_host_connection', 0 );
my $structures = $cmp->compare_conf($master, \%data::CEPHINGW, {}, {});
cmp_deeply($structures->{configs}, \%data::COMPARE1GW, 'Action hash ok');

done_testing();
