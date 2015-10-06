object template configure_create;

include 'devices';

prefix '/software/components/fstab';
'manage_blockdevs' = true;
'static/fs_types' = list('xfs');
'static/mounts' = list('/', '/boot', '/proc');
'keep/mounts' =  list('/', '/boot', '/home', '/sys');
'keep/fs_types' = list('gpfs', 'ceph', 'swap');
