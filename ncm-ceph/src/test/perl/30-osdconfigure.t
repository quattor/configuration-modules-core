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
my $mock = Test::MockModule->new('NCM::Component::ceph');
my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');

set_desired_output("/usr/bin/ceph -f json --cluster ceph mon dump",
    $data::MONJSON);
set_desired_output("/usr/bin/ceph -f json --cluster ceph osd dump", 
    $data::OSDDJSON);
set_desired_output("/usr/bin/ceph -f json --cluster ceph osd tree", 
    $data::OSDTJSON);
my $basestr = 'su - ceph -c /usr/bin/ssh 10.141.8.180 ';

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
my $id = $cluster->{config}->{fsid};

set_desired_output($basestr . 'cat /var/lib/ceph/osd/ceph-0/ceph_fsid',
    $data::FSID);
set_desired_output($basestr . 'cat /var/lib/ceph/osd/ceph-1/ceph_fsid',
    $data::FSID);
set_desired_output($basestr . 'cat /var/lib/ceph/osd/ceph-0/fsid',
    'e2fa588a-8c6c-4874-b76d-597299ecdf72');
set_desired_output($basestr . 'cat /var/lib/ceph/osd/ceph-1/fsid',
    'ae77eef3-70a2-4b64-b795-2dee713bfe41');
set_desired_output($basestr . '/bin/readlink /var/lib/ceph/osd/ceph-0','/var/lib/ceph/osd/sdc');
set_desired_output($basestr . '/bin/readlink -f /var/lib/ceph/osd/ceph-0/journal','/var/lib/ceph/log/sda4/osd-sdc/journal');
set_desired_output($basestr . '/bin/readlink -f /var/lib/ceph/osd/ceph-1/journal','/var/lib/ceph/log/sda4/osd-sdd/journal');
set_desired_output($basestr . '/bin/readlink /var/lib/ceph/osd/ceph-1','/var/lib/ceph/osd/sdd');

$cmp->use_cluster();
$cmp->{cfgfile} = 'tmpfile';

my $type = 'osd';
$mock->mock('get_host', 'ceph001.cubone.os' );
my $cephh = $cmp->osd_hash();
cmp_deeply($cephh, \%data::OSDS, 'OSD hash');
my $quath = $cluster->{osdhosts};

#diag explain $cephh;
cmp_deeply($cmp->flatten_osds($quath), \%data::FLATTEN, 'OSD flatten');
$cmp->init_commands();
$cmp->{hostname} = 'ceph001';
#Main  comparison function:
my $output = $cmp->process_osds($quath);
ok($output, 'ceph quattor cmp for mon');

cmp_deeply($cmp->{deploy_cmds}, \@data::ADDOSD, 'deploy commands prepared');

done_testing();
