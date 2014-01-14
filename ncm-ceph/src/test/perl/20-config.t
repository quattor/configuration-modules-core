# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 run Ceph command test
Test the runs of ceph commands


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
Readonly::Scalar my $PATH => '/software/components/ceph';


$CAF::Object::NoAction = 1;
my $mock = Test::MockModule->new('NCM::Component::ceph');

my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');
$cmp->use_cluster();

my $t = $cfg->getElement($PATH)->getTree();
my $cluster = $t->{clusters}->{ceph};
my $quath = $cluster->{config};
diag explain $quath;
$cmp->init_commands();
my $output = $cmp->process_config($quath);
#diag explain $cmp->get_config();
#diag explain $cmp->{cephgcfg};
ok($output, 'ceph quattor cmp for cfg');

my $dodeploy = $cmp->do_deploy();
ok($dodeploy, 'try making the config');
#diag explain $cmp->{cephcfg};


done_testing();
