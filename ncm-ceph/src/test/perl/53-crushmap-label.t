# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 Crushmap labeling test
Test the conversion of labeled crushmap buckets


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
#use Test::Quattor qw(labeled_crushmap);
use NCM::Component::ceph;
use CAF::Object;
use crushdata;
use Readonly;
Readonly::Scalar my $PATH => '/software/components/ceph';


$CAF::Object::NoAction = 1;

#my $cfg = get_config_for_profile('labeled_crushmap');
my $cmp = NCM::Component::ceph->new('ceph');

#my $t = $cfg->getElement($PATH)->getTree();
#my $cluster = $t->{clusters}->{ceph};

$cmp->use_cluster();
#my $crush = $cluster->{crushmap};
#$cmp->flatten_osds($cluster->{osdhosts});
#$cmp->quat_crush($crush, $cluster->{osdhosts});
#$cmp->crush_merge($crush->{buckets}, $cluster->{osdhosts}, []);

my $buckets = \@crushdata::RELBBUCKETS;
my $newbuckets = $cmp->labelize_buckets($buckets);
#diag explain $newbuckets;

cmp_deeply($newbuckets, \@crushdata::LBBUCKETS, 'labeled buckets ok');

done_testing();
