# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the build of the ceph configuration hash


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
my $mockcf = Test::MockModule->new('NCM::Component::Ceph::config');

set_desired_output("/usr/bin/ceph -f json --cluster ceph mon dump", $data::MONJSON);
set_desired_output("/usr/bin/ceph -f json --cluster ceph osd dump", $data::OSDDJSON);
set_desired_output("/usr/bin/ceph -f json --cluster ceph osd tree", $data::OSDTJSON);

set_desired_output("/usr/bin/ceph -f json --cluster ceph quorum_status", $data::STATE);

set_desired_output("/usr/bin/ceph -f json --cluster ceph mds stat",
    $data::MDSJSON);

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
$cmp->set_ssh_command(1);
$cmp->{fsid} = $cluster->{config}->{fsid};
$mock->mock('get_host'  => sub {
    my ($self,$host) = @_; 
    my $MAP = { 
        '10.141.8.180' => 'ceph001.cubone.os',
        '10.141.8.181' => 'ceph002.cubone.os',
        '10.141.8.182' => 'ceph003.cubone.os',
    };
    return $MAP->{$host};
    }
); 
$mockc->mock('test_host_connection' => sub {
    my ($self,$host) = @_; 
    my $MAP = { 
        'ceph001.cubone.os' => 1,
        'ceph002.cubone.os' => 1,
        'ceph003.cubone.os' => 0,
        };
    return $MAP->{$host};
    }
);
$mockcf->mock('pull_host_cfg' => sub {
    my ($self,$host) = @_;
    my $config = { 
        global => {
            fsid => 'e2fa588a-8c6c-4874-b76d-597299ecdf72'
        },  
        'osd.0' => {
            osd_objectstore => 'keyvaluestore-dev'
        },  
        'mon' => {
            option => 'value'
        }   
    };
    my $MAP = { 
        'ceph001.cubone.os' => $config,
        'ceph002.cubone.os' => {},
        'ceph003.cubone.os' => {},
    };
    return $MAP->{$host};
    }
);
my ($master, $mapping, $weights) = $cmp->get_ceph_conf();
cmp_deeply($master, \%data::CEPHFMAP, 'Ceph full config hash');

done_testing();
