object template fstab;

prefix '/software/components/fstab';

'protected/mounts' = list('/', '/home', '/boot');
'protected_mounts' = list('/', '/old');
'protected/filesystems' = list('gpfs', 'ceph');
'protected/strict' = true;
