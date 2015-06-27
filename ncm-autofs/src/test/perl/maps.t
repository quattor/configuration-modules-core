use strict;
use warnings;
use Test::More;
use CAF::Object;
use Test::Quattor qw(maps);
use NCM::Component::autofs;
use Test::Quattor::RegexpTest;
use Test::MockModule;
use Readonly;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Configure> method of the component.

=cut

my $mock = Test::MockModule->new('NCM::Component::autofs');
$mock->mock('_file_exists', sub {
    shift; my $fn = shift;
    return $fn =~ m/\/etc\/auto\.(master|export_map2)/ 
});

Readonly my $MAP2 => <<EOF;
# Test this
#/export/map2  -fstype=nfs4,nfsvers=4,minorversion=1,rw,soft,tcp,async,noatime,sec=sys myserver.mydomain:/export/path2
/export/map2b -fstype=nfs4,nfsvers=4,minorversion=1,rw,soft,tcp,async,noatime,sec=sys myserver.mydomain:/export/path2b
/export/map2d -fstype=nfs4,nfsvers=4,soft,tcp,async,noatime,sec=sys myserver.mydomain:/export/path2d
EOF

Readonly my $MASTER => <<EOF;
# Sample auto.master file
#
/misc   /etc/auto.misc
#
/net    -hosts
# Include /etc/auto.master.d/*.autofs
+dir:/etc/auto.master.d
#
+auto.master
EOF

set_file_contents("/etc/auto.export_map2", $MAP2);
set_file_contents("/etc/auto.master", $MASTER);

my $cfg = get_config_for_profile('maps');
my $cmp = NCM::Component::autofs->new('maps');

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

my ($fh, $rt);

$fh = get_file("/etc/auto.export_map1");
# preserve is false here, so FileWriter expected
isa_ok($fh, "CAF::FileWriter", "This is a CAF::FileWriter auto.export_map1 file written");
# but FileEditor is a FileWriter too, so test something more (and there's no isa_notok)
ok(! $fh->can('replace_lines'), "This is not a FileEditor");
diag("export_map2:\n$fh");

# Test all values
$rt = Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/export_map1',
    text => "$fh",
    );
$rt->test();



$fh = get_file("/etc/auto.export_map2");
# preserve is true here, so FileEditor expected
isa_ok($fh, "CAF::FileEditor", "This is a CAF::FileEditor auto.export_map2 file written");
ok($fh->can('replace_lines'), "This is a FileEditor (verify the test used to verify a FileWriter is not a FileEditor)");

diag("export_map2:\n$fh");

# Test all values
$rt = Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/export_map2',
    text => "$fh",
    );
$rt->test();

$fh = get_file("/etc/auto.master");
# preserveMaster is true here, so FileEditor expected
isa_ok($fh, "CAF::FileEditor", "This is a CAF::FileEditor auto.master file written");
ok($fh->can('replace_lines'), "This is a FileEditor (verify the test used to verify a FileWriter is not a FileEditor)");

diag("auto.master:\n$fh");

# Test all values
$rt = Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/auto_master',
    text => "$fh",
    );
$rt->test();


done_testing();
