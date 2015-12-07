# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

=pod
=head1 fstab data entries
# For testing ncm-fstab functions

=cut

package data;

use strict;
use warnings;

use Readonly;


Readonly::Hash our %PROTECTED => (
    'keep' => {
      'fs_types' => {
        'ceph' => 1,
        'gpfs' => 1
      },
      'mounts' => {
        '/' => 1,
        '/boot' => 1,
        '/home' => 1
      }
    },
    'static' => {
      'fs_types' => {},
      'mounts' => {
        '/' => 1,
        '/boot' => 1,
        '/usr' => 1
      }
    }
);

Readonly our $FSTAB_CONTENT => <<'EOF';

# /etc/fstab
# Created by anaconda on Wed Feb 26 09:20:11 2014
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/vg_sl65-lv_root /                       ext4    defaults        1 1
UUID=f6452f58-99b1-41fe-9840-f688157171f8 /boot                   ext4    noauto        1 2
/dev/mapper/vg_sl65-lv_swap swap                    swap    defaults        0 0
tmpfs                   /dev/shm                tmpfs   defaults        0 0
devpts                  /dev/pts                devpts  gid=5,mode=620  0 0
sysfs                   /sys                    sysfs   defaults        0 0
proc                    /proc                   proc    defaults        0 0
/dev/gpfsfs             /gpfs/fs1               gpfs    defaults        0   0
10.10.10.10:6789:/      /cephfs                 ceph    name=admin      0   0
/dev/sda5               /home                   ext4    defaults        1   2
/dev/sda6               /special                xfs     defaults        0   0   
EOF


Readonly::Hash our  %MOUNTS => (
   '/' => 1,
   '/boot' => 1,
   '/cephfs' => 1,
   '/gpfs/fs1' => 1,
   '/home' => 1,
);
