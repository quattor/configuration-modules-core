# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the flatten_buckets method


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(basic_crushmap);
use Test::MockModule;
use NCM::Component::ceph;
use CAF::Object;
use crushdata;
use Readonly;

$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('basic_crushmap');
my $cmp = NCM::Component::ceph->new('ceph');

my $t = $cfg->getElement($cmp->prefix())->getTree();
my $cluster = $t->{clusters}->{ceph};

$cmp->use_cluster();
my $buckets = \@crushdata::REBUCKETS;
my $newbuckets=[];
$cmp->flatten_buckets($buckets, $newbuckets);

cmp_deeply($newbuckets, \@crushdata::FLBUCKETS, 'hash from quattor built');

done_testing();
