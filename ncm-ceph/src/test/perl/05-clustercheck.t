# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the cluster_ready_check method

=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(basic_cluster);
use NCM::Component::ceph;
use CAF::Object;
use data;
use File::Temp qw(tempdir);
use Config::Tiny;
use Data::Structure::Util qw( unbless );
use Readonly;

$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};

$cmp->use_cluster();
my $is_deploy = 1;
my $hostname = 'ceph001';
my $gather1 = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph gatherkeys ceph001.cubone.os";
my $gather2 = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph gatherkeys ceph002.cubone.os";
my $gather3 = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph gatherkeys ceph003.cubone.os";
my @gathers = ($gather1, $gather2, $gather3);
set_desired_output("/usr/bin/ceph -f json --cluster ceph status", $data::STATE);


# Totally new cluster
foreach my $gcmd (@gathers) {
    set_command_status($gcmd,1);
    set_desired_err($gcmd,'');
}
my $usr =  getpwuid($<);
my $tempdir = tempdir(CLEANUP => 1);
my $cephusr = { 'homeDir' => $tempdir, 'uid' => $usr , 'gid' => $usr };
$cmp->gen_extra_config($cluster);
my $clustercheck= $cmp->cluster_exists_check($cluster, $cephusr, 'ceph');
my $cmd;
foreach my $gcmd (@gathers) {
    $cmd = get_command($gcmd);
    ok(defined($cmd), "no cluster: gather had been tried");
}
ok(!$clustercheck, "no cluster, return 0");

my $initcheck= $cmp->init_qdepl($cluster->{config}, $cephusr);
$cmp->write_config($cluster->{config}, "$tempdir/ceph.conf");
ok(-d $tempdir. '/ncm-ceph/.git', "tmpdirs created");
ok(-f $tempdir . '/ceph.conf', "ceph-deploy config file created");

my $tinycfg = Config::Tiny->read($tempdir . '/ceph.conf');
my $cfghash = {   'global' => {
    'fsid' => 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
    'mon_initial_members' => 'ceph001, ceph002, ceph003',   
    'mon_host' => 'ceph001.cubone.os, ceph002.cubone.os, ceph003.cubone.os',   
    'osd_crush_update_on_start' => 1,
    }
};
cmp_deeply(unbless($tinycfg), $cfghash);
done_testing();
