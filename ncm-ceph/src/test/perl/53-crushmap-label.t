# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION
Test the conversion of labeled crushmap buckets


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(labeled_crushmap);
use NCM::Component::ceph;
use CAF::Object;
use crushdata;
use Readonly;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::ceph->new('ceph');
$cmp->use_cluster();

my $generate = 0;

if ($generate) {
    my $cfg = get_config_for_profile('labeled_crushmap');
    my $t = $cfg->getElement($cmp->prefix())->getTree();
    my $cluster = $t->{clusters}->{ceph};
    my $mapping = {};

    my $crush = $cluster->{crushmap};
    while (my ($hostname, $host) = each(%{$cluster->{osdhosts}})) {
        $cmp->structure_osds($hostname, $host); # Is normally done in the daemon part
        while (my ($osdkey, $osd) = each(%{$host->{osds}})) {
            $cmp->add_to_mapping($mapping, 'osd.0', $hostname, $osd->{osd_path});
        }
    }   

    $cmp->crush_merge($crush->{buckets}, $cluster->{osdhosts}, [], { mapping => $mapping });

    diag explain $crush->{buckets};
}

my $buckets = \@crushdata::RELBBUCKETS;
my $newbuckets = $cmp->labelize_buckets($buckets);
#diag explain $newbuckets;

cmp_deeply($newbuckets, \@crushdata::LBBUCKETS, 'labeled buckets ok');

done_testing();
