# ${license-info}
# ${author-info}
# ${build-info}

=pod

=head1 test for protected mounts and filesystems

Tests for building the protected hash, and the valid mounts.

=cut

use strict;
use warnings;
use Readonly;
Readonly my $FSTAB => 'target/test/etc/fstab';
BEGIN{
    # This only works because the constant of NCM::Filesystem is used in a ncm-fstab sub
    use Test::Quattor;
    use NCM::Filesystem;
    undef &{NCM::Filesystem::FSTAB};
    *{NCM::Filesystem::FSTAB} =  sub () {$FSTAB} ;
}

use CAF::FileEditor;
use CAF::Object;
use File::Basename;
use File::Path qw(mkpath);
use Test::Deep;
use Test::More;
use Test::Quattor qw(fstab fstab_depr);
use NCM::Component::fstab;

is(NCM::Filesystem::FSTAB, $FSTAB);
mkpath dirname $FSTAB;

use data;
my $cfg = get_config_for_profile('fstab');
my $cmp = NCM::Component::fstab->new('fstab');
my $tree = $cfg->getTree($cmp->prefix());
my $protected = $cmp->protected_hash($tree);
cmp_deeply($protected, \%data::PROTECTED, 'protected hash ok');

set_file_contents($FSTAB, $data::FSTAB_CONTENT);
my $fstab = CAF::FileEditor->new ($FSTAB);

my %mounts = ();
%mounts = $cmp->valid_mounts($protected->{keep}, $fstab, %mounts);
cmp_deeply(\%mounts, \%data::MOUNTS, 'valid mounts ok');

$cfg = get_config_for_profile('fstab_depr');
$tree = $cfg->getTree($cmp->prefix());
%mounts = ();
$protected = $cmp->protected_hash($tree);
%mounts = $cmp->valid_mounts($protected->{keep}, $fstab, %mounts);
cmp_deeply(\%mounts, \%data::MOUNTS, 'valid mounts (deprecated) ok');

done_testing();
