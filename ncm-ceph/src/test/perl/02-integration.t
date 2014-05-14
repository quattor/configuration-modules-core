# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the call of submodules


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(basic_crushmap);
use Test::MockModule;
use NCM::Component::ceph;
use CAF::Object;
use data;
use Readonly;

$CAF::Object::NoAction = 1;
my $cfg = get_config_for_profile('basic_crushmap');
my $cmp = NCM::Component::ceph->new('ceph');
my $mock = Test::MockModule->new('NCM::Component::ceph');
my $daemonmock = Test::MockModule->new('NCM::Component::Ceph::daemon');

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
my $id = $cluster->{config}->{fsid};
my $cephusr = {};
my $gvalues = { 
    clname => 'ceph',
    hostname => 'ceph001',
    is_deploy => 1,
    cephusr => $cephusr,
    qtmp => 'bar'
};

$mock->mock('do_prepare_cluster', 1 );
$daemonmock->mock('check_daemon_configuration', 1 );
$mock->mock('ceph_crush', 1 );
$mock->mock('get_osd_name', 1 );
$mock->mock('cmp_crush', 1 );
$cmp->gen_extra_config($cluster); #From do_prepare_cluster
my $output = $cmp->do_configure($cluster, $gvalues);
ok($output, 'do_configure ok');
my $cmdstr = "su - ceph -c /usr/bin/ceph-deploy --cluster ceph config push ceph001.cubone.os";
my $cmd = get_command($cmdstr);
ok(defined($cmd), "config section invoked");

done_testing();
