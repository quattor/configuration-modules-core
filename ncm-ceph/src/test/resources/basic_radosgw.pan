object template basic_radosgw;

variable MONITOR1 =  dict(
    'fqdn', 'ceph001.cubone.os',
    'up', true,
);

variable RADOSGW = dict(
    'config', dict(
        'host' , 'ceph001',
        'foo', 'bar',
    )
);
variable CONFIG = dict (
    'fsid' , 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
    'mon_initial_members', list ('ceph001', 'ceph002', 'ceph003')
);

prefix '/software/components/ceph/clusters';

'ceph' = dict (
    'config', CONFIG,
    'monitors', dict (
        'ceph001', MONITOR1,
    ),
    'radosgwh' , dict(
        'ceph001', dict(
            'fqdn', 'ceph001.cubone.os',
            'gateways', dict(
                'gateway', RADOSGW,
            ),
        ),
    ),
    'deployhosts', dict (
        'ceph002', 'ceph002.cubone.os'
    )

);

'/system/network/hostname' = 'ceph002';
'/system/network/domainname' = 'cubone.os';

'/software/components/accounts/users/ceph' =
    dict('homeDir', '/tmp', 'gid', '111' );
'/software/components/accounts/groups/ceph' = dict('gid', '111');
