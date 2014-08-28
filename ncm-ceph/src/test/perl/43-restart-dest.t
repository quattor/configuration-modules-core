# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the restarts and destroys  of new daemons


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

my $output =$cmp->destroy_daemons(\%data::DESTROYD,\%data::MAPPING );
ok($output, 'destroy sub ran');
$output =$cmp->restart_daemons(\%data::RESTARTD );
ok($output, 'restart output ran');

done_testing();
