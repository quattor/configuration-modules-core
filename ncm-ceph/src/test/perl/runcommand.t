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
use Test::Quattor;
use NCM::Component::ceph;
use CAF::Object;
use data;

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::ceph->new("ceph");

set_desired_output("ceph -f json mon dump", $data::jsonout);

my @fullcmd = qw(ceph -f json mon dump);
my @cephcmd = qw(mon dump);

my $output = $cmp->run_command(\@fullcmd);
is($output,$data::jsonout);
my $outputc = $cmp->run_ceph_command(\@cephcmd);
is($outputc,$data::jsonout);
my %jhash = $cmp->json_to_hash($data::jsonout);
is(%jhash,%data::jsondecode);
diag explain \%jhash;
diag explain \%data::jsondecode;

done_testing();
