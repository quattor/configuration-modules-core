# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the configuration of the MDSs

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

set_desired_output("/usr/bin/ceph -f json --cluster ceph mds stat",
    $data::MDSJSON);

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};


$cmp->use_cluster();
$cmp->{clname} = 'ceph';
$cmp->{cfgfile} = 'tmpfile';
$cmp->set_ssh_command(1);
$mock->mock('get_host', 'ceph001.cubone.os' );
my $master = {};
$cmp->mds_hash($master);
cmp_deeply($master, \%data::MDSS);
my $quath = $cluster->{mdss};

my $donecmd = 'su - ceph -c /usr/bin/ssh -o ControlMaster=auto -o ControlPersist=600 -o ControlPath=/tmp/ssh_mux_%h_%p_%r ceph002.cubone.os test -e /var/lib/ceph/mds/ceph-ceph002/done';

set_command_status($donecmd,0);
set_desired_err($donecmd,'');
my $output = $cmp->prep_mds('ceph002', { fqdn => 'ceph002.cubone.os' });
ok($output, 'no new mds');

done_testing();
