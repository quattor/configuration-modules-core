object template fstab;

prefix '/software/components/fstab';

'static/mounts' = list('/', '/boot', '/usr');
'keep/mounts' =  list('/', '/boot', '/home');
'keep/filesystems' = list('gpfs', 'ceph');
