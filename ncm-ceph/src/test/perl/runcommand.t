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

$CAF::Object::NoAction = 1;

my $cmp = NCM::Component::ceph->new("ceph");

set_desired_output("ceph mon dump -f json", '{"epoch":11,"fsid":"a94f9906-ff68-487d-8193-23ad04c1b5c4","modified":"2013-12-11 10:40:44.403149","created":"0.000000","mons":[{"rank":0,"name":"ceph002b","addr":"10.141.8.181:6754\/0"},{"rank":1,"name":"ceph001","addr":"10.141.8.180:6789\/0"},{"rank":2,"name":"ceph003","addr":"10.141.8.182:6789\/0"}],"quorum":[0,1,2]}');

my @fullcmd = qw(ceph mon dump -f json);
my @cephcmd = qw(mon dump -f json);
my $t = '{"epoch":11,"fsid":"a94f9906-ff68-487d-8193-23ad04c1b5c4","modified":"2013-12-11 10:40:44.403149","created":"0.000000","mons":[{"rank":0,"name":"ceph002b","addr":"10.141.8.181:6754\/0"},{"rank":1,"name":"ceph001","addr":"10.141.8.180:6789\/0"},{"rank":2,"name":"ceph003","addr":"10.141.8.182:6789\/0"}],"quorum":[0,1,2]}';

my $output = $cmp->run_command(\@fullcmd);
is($output,$t);
my $outputc = $cmp->run_ceph_command(\@cephcmd);
is($outputc,$t);


done_testing();
