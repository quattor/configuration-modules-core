# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the configuration of the OSDs


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

$CAF::Object::NoAction = 1;
my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');
my $mock = Test::MockModule->new('NCM::Component::Ceph::daemon');
my $mockc = Test::MockModule->new('NCM::Component::Ceph::commands');

set_desired_output("/usr/bin/ceph -f json --cluster ceph mon dump", $data::MONJSON);
set_desired_output("/usr/bin/ceph -f json --cluster ceph osd dump", $data::OSDDJSON);
set_desired_output("/usr/bin/ceph -f json --cluster ceph osd tree", $data::OSDTJSON);


my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
my $id = $cluster->{config}->{fsid};

set_desired_output("$data::OSD_SSH_BASE_CMD $data::CATCMD /var/lib/ceph/osd/ceph-0/ceph_fsid",
    $data::FSID);
set_desired_output("$data::OSD_SSH_BASE_CMD $data::CATCMD /var/lib/ceph/osd/ceph-1/ceph_fsid",
    $data::FSID);
set_desired_output("$data::OSD_SSH_BASE_CMD $data::CATCMD /var/lib/ceph/osd/ceph-0/fsid",
    'e2fa588a-8c6c-4874-b76d-597299ecdf72');
set_desired_output("$data::OSD_SSH_BASE_CMD $data::CATCMD /var/lib/ceph/osd/ceph-1/fsid",
    'ae77eef3-70a2-4b64-b795-2dee713bfe41');
set_desired_output("$data::OSD_SSH_BASE_CMD /bin/readlink /var/lib/ceph/osd/ceph-0", '/var/lib/ceph/osd/sdc');
set_desired_output("$data::OSD_SSH_BASE_CMD /bin/readlink -f /var/lib/ceph/osd/ceph-0/journal", '/var/lib/ceph/log/sda4/osd-sdc/journal');
set_desired_output("$data::OSD_SSH_BASE_CMD /bin/readlink -f /var/lib/ceph/osd/ceph-1/journal", '/var/lib/ceph/log/sda4/osd-sdd/journal');
set_desired_output("$data::OSD_SSH_BASE_CMD /bin/readlink /var/lib/ceph/osd/ceph-1", '/var/lib/ceph/osd/sdd');

$cmp->use_cluster();
$cmp->{clname} = 'ceph';
$cmp->{cfgfile} = 'tmpfile';
$cmp->set_ssh_command(1);

$cmp->{fsid} = $cluster->{config}->{fsid};
my $type = 'osd';
$mock->mock('get_host', 'ceph001.cubone.os' );
$mockc->mock('test_host_connection', 1 );
my $master = {};
my $weights = {};
my $mapping = {};
$cmp->osd_hash($master, $mapping, $weights);
cmp_deeply($master, \%data::OSDS, 'OSD hash');
cmp_deeply($mapping, \%data::MAPPING, 'OSD map');
cmp_deeply($weights, \%data::WEIGHTS, 'OSD map');
my $quath = $cluster->{osdhosts};

my %tmp = ();
while (my ($hostname, $host) = each(%{$quath})) {
    my $par= $cmp->structure_osds($hostname, $host);
    %tmp = (%tmp, %$par);
    
}
cmp_deeply(\%tmp, \%data::FLATTEN, 'OSD flatten');
$cmp->{hostname} = 'ceph001';


done_testing();
