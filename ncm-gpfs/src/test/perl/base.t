# # -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 DESCRIPTION

Test the configuration of the gpfs rpms and files


=cut


use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(base);
use NCM::Component::gpfs;
use CAF::Object;
use Readonly;

$CAF::Object::NoAction = 1;

my $cfg = get_config_for_profile('base');
my $cmp = NCM::Component::gpfs->new('gpfs');

my $mmsdrfs = <<'EOF';
%%9999%%:00_VERSION_LINE::1423:3:192::lc:test1.test.gent.vsc:test1.test.gent.vsc:0:/usr/bin/ssh:/usr/bin/scp:4645050944951318114:lc2:1367931632::test1.test.gent.vsc:2:0:2:2::::central:0.0:
%%home%%:03_COMMENT::1:
%%home%%:03_COMMENT::2:    This is a machine generated file.  Do not edit!  
%%home%%:20_MEMBER_NODE::1:1:test11.test.gent.vsc:172.24.14.193:test11.test.gent.vsc:manager:X:::::test11.test.gent.vsc:test11:1510:4.2.1.0:Linux:Q::::D::server::
%%home%%:20_MEMBER_NODE::1:1:test12.test.gent.vsc:172.24.14.194:test12.test.gent.vsc:manager:X:::::test12.test.gent.vsc:test12:1510:4.2.1.0:Linux:Q::::D::server::
EOF

my $keyData = <<'EOF';
clusterName=shuppet2.shuppet.gent.vsc
clusterID=10670523911072744868
genkeyFormat=3
EOF
my $mmsdrfs_cmd = '/usr/bin/curl -s -f --cacert /etc/sindes/certs/ca-test.ugent.be.crt --cert /etc/sindes/certs/client_cert_key.pem https://test.ugent.be:446/test/mmsdrfs';
my $keyData_cmd = '/usr/bin/curl -s -f --cacert /etc/sindes/certs/ca-test.ugent.be.crt --cert /etc/sindes/certs/client_cert_key.pem https://test.ugent.be:446/test/keydata2';
set_desired_output($mmsdrfs_cmd, $mmsdrfs);
set_desired_output($keyData_cmd, $keyData);
ok($cmp->get_cfg($cfg), 'get_cfg ran succesfully');
ok(get_command($mmsdrfs_cmd), 'mmsdrfs file fetched');
ok(get_command($keyData_cmd), 'keydata file fetched');

my $keyData_fh = get_file("/var/mmfs/ssl/stage/genkeyData1");
is(*$keyData_fh->{options}->{mode}, 0600, "File has correct permissions");
is("$keyData_fh", $keyData, 'keydata file ok');

done_testing();
