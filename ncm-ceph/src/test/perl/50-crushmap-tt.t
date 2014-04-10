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
use Test::Quattor qw(basic_crushmap_tt);
use Test::MockModule;
use NCM::Component::ceph;
use CAF::Object;
use crushdata;
use Readonly;
Readonly::Scalar my $PATH => '/software/components/ceph';


$CAF::Object::NoAction = 1;
my $mock = Test::MockModule->new('NCM::Component::ceph');

my $cfg = get_config_for_profile('basic_crushmap_tt');
my $cmp = NCM::Component::ceph->new('ceph');


my $t = $cfg->getElement($PATH)->getTree();
my $cluster = $t->{clusters}->{ceph};

my $crush = $cluster->{crushmap};
my $str = "# begin crush map\n";
ok($cmp->template()->process('ceph/crush.tt', $crush, \$str),
   "Template successfully rendered");
# Very basic template, not filled in
is($str,$crushdata::BASEMAP, 'written crushmap ok');
is($cmp->template()->error(), "", "No errors in rendering the template");

$cmp->use_cluster();

done_testing();
