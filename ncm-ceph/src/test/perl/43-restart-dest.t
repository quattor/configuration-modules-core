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
use Test::Quattor::RegexpTest;
use NCM::Component::ceph;
use CAF::Object;
use Cwd;
use data;
use Data::Structure::Util qw( unbless );
use File::Temp qw(tempdir);
use Readonly;

$CAF::Object::NoAction = 1;
my $regexpdir= getcwd()."/src/test/resources/regexps";

my $cfg = get_config_for_profile('basic_cluster');
my $cmp = NCM::Component::ceph->new('ceph');
my $mock = Test::MockModule->new('NCM::Component::Ceph::commands');
my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};
$cmp->use_cluster();

my $results = [];
$mock->mock('print_cmds', sub {
    my ($self, $cmds) = @_;
    $results = join("\n", $results, @$cmds);
}
);
my $output =$cmp->destroy_daemons(\%data::DESTROYD,\%data::MAPPING );
ok($output, 'destroy sub ran');

$output =$cmp->restart_daemons(\%data::RESTARTD );
ok($output, 'restart output ran');
diag $results;
Test::Quattor::RegexpTest->new(
    regexp => "$regexpdir/destroyrestart",
        text => "$results"
        )->test();

done_testing();
