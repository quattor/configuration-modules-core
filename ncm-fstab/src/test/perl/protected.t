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
use CAF::FileEditor;
use CAF::Object;
use NCM::Component::fstab;
use Test::Deep;
use Test::More;
use Test::Quattor qw(fstab);

use data;
$CAF::Object::NoAction = 1;
my $cfg = get_config_for_profile('fstab');
my $cmp = NCM::Component::fstab->new('fstab');

my $protected = $cmp->protected_hash($cfg);
cmp_deeply($protected, \%data::PROTECTED, 'protected hash ok');

my $fstab = CAF::FileEditor->new ("/etc/fstab" );

set_file_contents('/etc/fstab', $data::FSTAB_CONTENT);
my %mounts = ();
%mounts = $cmp->valid_mounts($protected, $fstab, %mounts);
cmp_deeply(\%mounts, \%data::MOUNTS, 'valid mounts ok');

done_testing();
