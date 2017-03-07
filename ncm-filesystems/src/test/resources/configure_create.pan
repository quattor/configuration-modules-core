object template configure_create;

include 'devices';

prefix '/software/components/fstab';
'static/fs_types' = list('xfs');
'static/mounts' = list('/', '/boot', '/proc');
'keep/mounts' =  list('/', '/boot', '/home', '/sys');
'keep/fs_types' = list('gpfs', 'ceph', 'swap');

prefix '/software/components/filesystems';
'manage_blockdevs' = true;
