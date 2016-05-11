# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the compare function and the build of the action hashes


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
my $mockc = Test::MockModule->new('NCM::Component::Ceph::commands');
my $mock = Test::MockModule->new('NCM::Component::Ceph::daemon');
my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
$cmp->use_cluster();
$mockc->mock('test_host_connection', 0 );
my $structures = $cmp->compare_conf(\%data::QUATIN, \%data::CEPHIN, \%data::MAPPING, {});
cmp_deeply($structures, \%data::COMPARE1, 'Action hash ok');

$mockc->mock('test_host_connection', 1 );
$mock->mock('prep_mds', 0 );

$structures = $cmp->compare_conf(\%data::QUATIN, \%data::CEPHIN, \%data::MAPPING, { max_add_osd_failures_per_host => 1 }); 
cmp_deeply($structures, \%data::COMPARE2, 'Quattor config hash');

done_testing();
