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
use Test::MockModule;
use NCM::Component::ceph;
use CAF::Object;
use data;
use Readonly;

$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');

set_desired_output("/usr/bin/ceph -f json --cluster ceph mds stat",
    $data::MDSJSON);

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};


$cmp->use_cluster();
$cmp->{cfgfile} = 'tmpfile';

my $cephh = $cmp->mds_hash();
cmp_deeply($cephh, \%data::MDSS);
my $quath = $cluster->{mdss};

my $donecmd = 'su - ceph -c /usr/bin/ssh ceph002.cubone.os test -e /var/lib/ceph/mds/ceph-ceph002/done';

set_command_status($donecmd,1);
set_desired_err($donecmd,'');
$cmp->init_commands();
$cmp->{hostname} = 'ceph001';
#Main  comparison function:
my $output = $cmp->process_mdss($quath);
ok($output, 'ceph quattor cmp for mds');
cmp_deeply($cmp->{deploy_cmds}, \@data::ADDMDS, 'deploy commands prepared');

done_testing();
