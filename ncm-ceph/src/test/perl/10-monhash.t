# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the configuration of the monitor


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
my $mock = Test::MockModule->new('NCM::Component::Ceph::daemon');

set_desired_output("/usr/bin/ceph -f json --cluster ceph mon dump", 
    $data::MONJSON);
set_desired_output("/usr/bin/ceph -f json --cluster ceph quorum_status", $data::STATE);

$cmp->use_cluster();
$cmp->{clname} = 'ceph';
$cmp->{cfgfile} = 'tmpfile';

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
my $id = $cluster->{config}->{fsid};

my $type = 'mon';
my $quath = $cluster->{monitors};

$mock->mock('get_host', 'ignore' );
my $master = {};
$cmp->mon_hash($master);
cmp_deeply($master,\%data::MONS, 'build monitor hash');
#
done_testing();
