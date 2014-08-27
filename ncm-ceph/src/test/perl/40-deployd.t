# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the deployment of new daemons


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
my $mockd = Test::MockModule->new('NCM::Component::Ceph::daemon');
my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
$cmp->use_cluster();
$mock->mock('write_and_push', 1);

$mockd->mock('add_osd_to_config', 1);
my $tinies = {};
my $output =$cmp->deploy_daemons(\%data::DEPLOYD,$tinies );
ok($output, 'Deployment ok');

my $monaddstring = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph mon create ceph003.cubone.os";
my $cmd = get_command($monaddstring);
ok(defined($cmd), "mon add was invoked");
my $mdsaddstring = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph mds create ceph002.cubone.os:ceph002";
$cmd = get_command($mdsaddstring);
ok(defined($cmd), "mds add was invoked");
my $osdaddstring = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph osd create ceph002.cubone.os:/var/lib/ceph/osd/sdc:/var/lib/ceph/log/sda4/osd-sdc/journal";
$cmd = get_command($osdaddstring);
ok(defined($cmd), "osd add was invoked");

done_testing();
