# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the build of the quattor configuration hash


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

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};

my $master = $cmp->get_quat_conf($cluster);
cmp_deeply($master, \%data::QUATMAP, 'Quattor config hash');

done_testing();
