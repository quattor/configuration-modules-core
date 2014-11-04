object template basic_radosgw;

variable MONITOR1 =  nlist(
    'fqdn', 'ceph001.cubone.os',
    'up', true,
);

variable RADOSGW = nlist(
    'fqdn', 'ceph001.cubone.os',
    'config', nlist(
        'host' , 'ceph001',
        'foo', 'bar',
    )
);
variable CONFIG = nlist (
    'fsid' , 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
    'mon_initial_members', list ('ceph001', 'ceph002', 'ceph003')
);

prefix '/software/components/ceph/clusters';

'ceph' = nlist (
    'config', CONFIG,
    'monitors', nlist (
        'ceph001', MONITOR1,
    ),
    'radosgws', nlist(
        'ceph001', RADOSGW,
    ),
    'deployhosts', nlist (
        'ceph002', 'ceph002.cubone.os'
    )

);         

'/system/network/hostname' = 'ceph002';
'/system/network/domainname' = 'cubone.os';

'/software/components/accounts/users/ceph' = 
    nlist('homeDir', '/tmp', 'gid', '111' );
'/software/components/accounts/groups/ceph' = nlist('gid', '111');
