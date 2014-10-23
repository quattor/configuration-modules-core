# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the  build of the config::tiny hashes


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(basic_cluster);
use NCM::Component::ceph;
use CAF::Object;
use data;
use Data::Structure::Util qw( unbless );
use File::Temp qw(tempdir);
use Readonly;

$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');
my $mock = Test::MockModule->new('NCM::Component::Ceph::config');
my $mockc = Test::MockModule->new('NCM::Component::Ceph::crushmap');
my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
$cmp->use_cluster();
$mock->mock('write_and_push', 1);
my $tinies = $cmp->set_and_push_configs(\%data::CONFIGS);
my $osd =  {
    'config' => {
        'osd_objectstore' => 'keyvaluestore-dev'
    },
    'fqdn' => 'ceph002.cubone.os',
    'host' => 'ceph002',
    'journal_path' => '/var/lib/ceph/log/sda4/osd-sdc/journal',
    'osd_path' => '/var/lib/ceph/osd/sdc'
};

$mockc->mock('get_osd_name', "osd.2");
my $mapping = {};
$cmp->add_osd_to_config('ceph002', $tinies->{ceph002}, $osd, {}, $mapping);
cmp_deeply($mapping, \%data::MAPADD, 'adding to mapping succesful');
cmp_deeply(unbless($tinies), \%data::TINIES, 'config structure to write ok');

done_testing();
