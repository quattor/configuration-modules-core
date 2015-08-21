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
use LC::Check;
use NCM::Component::fstab;
use Test::Deep;
use Test::More;
use Test::Quattor qw(configure);

use data;
$CAF::Object::NoAction = 1;
$LC::Check::NoAction = 1;
my $cfg = get_config_for_profile('configure');
my $cmp = NCM::Component::fstab->new('fstab');
use NCM::Blockdevices;
$NCM::Blockdevices::this_app = $cmp;

set_file_contents('/etc/fstab', $data::FSTAB_CONTENT);

$cmp->Configure($cfg);
my $fh = get_file('/etc/fstab');
like($fh, qr{^/dev/mapper/vg_sl65-lv_root\s+/\s+ext4\s+defaults\s+1\s+1\s*[^/]*$}m, 'root not changed');
like($fh, qr{^UUID=f6452f58-99b1-41fe-9840-f688157171f8\s+/boot\s+ext4\s+defaults\s+1\s+2\s*[^/]*$}m, '/boot not changed');
like($fh, qr{^/dev/mapper/vg_sl65-lv_swap\s+swap\s+swap\s+defaults\s+0\s+0\s*[^/]*$}m, 'swap mount ok');
like($fh, qr{^sysfs\s+/sys\s+sysfs\s+defaults\s+0\s+0\s*[^/]*$}m, '/sys mount ok');
like($fh, qr{^/dev/gpfsfs\s+/gpfs/fs1\s+gpfs\s+defaults\s+0\s+0\s*[^/]*$}m, 'GPFS mount ok');
like($fh, qr{^10.10.10.10:6789:/\s+/cephfs\s+ceph\s+name=admin\s+0\s+0\s*[^/]*$}m, 'Mount /cephfs not deleted');
like($fh, qr{^/dev/sda3\s+/new\s+ext4\s+auto\s+0\s+0\s*[^/]*$}m, 'Mount /new entry added to fstab');
like($fh, qr{^LABEL=FRIETJES\s+/food\s+chokotoFS\s+auto\s+0\s+0\s*[^/]*$}m, 'Mount /food entry added to fstab');

done_testing();
