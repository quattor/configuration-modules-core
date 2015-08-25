# -*- mode: cperl -*-
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
    use NCM::Filesystem;
    undef &{NCM::Filesystem::FSTAB};
    *{NCM::Filesystem::FSTAB} =  sub () {$FSTAB} ;
}

use CAF::FileEditor;
use CAF::Object;
use File::Basename;
use File::Path qw(mkpath);
use NCM::Component::fstab;
use Test::Deep;
use Test::More;
use Test::Quattor qw(fstab fstab_depr);

is(NCM::Filesystem::FSTAB, $FSTAB);
mkpath dirname $FSTAB;

use data;
$CAF::Object::NoAction = 1;
my $cfg = get_config_for_profile('fstab');
my $cmp = NCM::Component::fstab->new('fstab');

my $protected = $cmp->protected_hash($cfg);
cmp_deeply($protected, \%data::PROTECTED, 'protected hash ok');

my $fstab = CAF::FileEditor->new ($FSTAB);

set_file_contents($FSTAB, $data::FSTAB_CONTENT);
my %mounts = ();
%mounts = $cmp->valid_mounts($protected->{keep}, $fstab, %mounts);
cmp_deeply(\%mounts, \%data::MOUNTS, 'valid mounts ok');

$cfg = get_config_for_profile('fstab_depr');

%mounts = ();
$protected = $cmp->protected_hash($cfg);
%mounts = $cmp->valid_mounts($protected->{keep}, $fstab, %mounts);
cmp_deeply(\%mounts, \%data::MOUNTS, 'valid mounts (deprecated) ok');

done_testing();
