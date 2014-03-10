unique template site/filesystems/ceph;

include { 'quattor/functions/filesystem' };

prefix '/system/blockdevices';
variable DISK_SWAP_SIZE = 4*GB;

# Boot disk sda
'partitions' = partitions_add(
        'sda', nlist('sda1', 256*MB,
                     'sda2', 10*GB,
                     'sda3', DISK_SWAP_SIZE,
                     'sda4', -1));


'physical_devs/sda/label' = 'msdos';
'physical_devs/sdb/label' = 'none';
'physical_devs' = {
    foreach (disk;data;value('/hardware/harddisks')) {
        if (data['capacity'] > 1000*GB) {
            SELF[disk]['label'] = 'none';
        };
    };
   SELF;
};

# OS filesystems
'/system/filesystems' = { 
    base= nlist(
        'mount', true,
        'format', true,
        'preserve', false
    );
    append(merge(base,nlist(
        'mountpoint', '/boot',
        'type', 'ext2',
        'block_device', 'partitions/sda1'
        )));
    append(merge(base, nlist(
        'mountpoint', 'swap',
        'type', 'swap',
        'block_device', 'partitions/sda3',
        )));
    append(merge(base, nlist(
        'mountpoint', '/',
        'type', 'ext4',
        'block_device', 'partitions/sda2',
        )));
};
# mkfs and mount optoins
# see https://github.com/ceph/ceph/blob/master/src/ceph-disk
variable CEPH_DISK_OPTIONS = nlist(
    'xfs' , nlist(
        'mkfsopts', '-i size=2048',
        'mountopts', 'noatime'
    ),  
    'ext4', nlist(
        'mountopts', 'noatime,user_xattr',
    ),  
    'btrfs', nlist(
        'mkfsopts', '-m single -l 32768 -n 32768',
        'mountopts', 'noatime,user_subvol_rm_allowed',
    )   
);

variable CEPH_FS = 'xfs';

# ceph OSD and journal fs
'/system/filesystems' = { 
    base= nlist(
        'mount', true,
        'format', false,
        'preserve', true,
        'type', CEPH_FS,
    );
    append(merge(base, CEPH_DISK_OPTIONS[CEPH_FS], nlist(
        'mountpoint', '/var/lib/ceph/log/sda4',
        'block_device', 'partitions/sda4',
    )));
    foreach (disk;label;value('/system/blockdevices/physical_devs')) {
        if (label['label'] == 'none' ) {
		    if (disk == 'sdb') {
			    typ='log';
		    } else {
			    typ='osd';
		    };
            append(merge(base, CEPH_DISK_OPTIONS[CEPH_FS], nlist(
		        'mountpoint', format('/var/lib/ceph/%s/%s',typ,disk),
          	    'block_device', format('physical_devs/%s',disk),
                )));
        };
    };
};

'/system/blockdevices/logical_volumes' = nlist();

variable AII_OSINSTALL_OPTION_CLEARPART = list(DISK_BOOT_DEV);

