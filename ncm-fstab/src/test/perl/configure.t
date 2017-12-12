# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 test for ncm-fstab Configure method

Tests for adding, changing and deleting entries in /etc/fstab and mounting

=cut

use strict;
use warnings;
use Readonly;

use CAF::FileEditor;
use CAF::Object;
use File::Basename;
use LC::Check;
use Test::Deep;
use Test::More;
use Test::Quattor qw(configure);
use Test::Quattor::RegexpTest;
use NCM::Component::fstab;
use data;

# for LC::Check::directory
$LC::Check::NoAction = 1;

my $cfg = get_config_for_profile('configure');
my $cmp = NCM::Component::fstab->new('fstab');

set_file_contents(NCM::Filesystem::FSTAB, $data::FSTAB_CONTENT);

# Test all values
$cmp->Configure($cfg);
my $fh = get_file(NCM::Filesystem::FSTAB);

my $rt = Test::Quattor::RegexpTest->new(
    regexp => 'src/test/resources/fstab_regextest',
    text => "$fh",
    );
$rt->test();

my $cmd = get_command("/bin/mount -o remount /");
ok(defined($cmd), "remount / was invoked");
$cmd=get_command("/bin/mount -o remount /boot");
ok(!defined($cmd), "remount /boot was not invoked");


done_testing();
