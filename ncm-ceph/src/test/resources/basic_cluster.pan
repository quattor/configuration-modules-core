object template basic_cluster;


variable OSDS = nlist (
    'ceph001', nlist (
        'fqdn', 'ceph001.cubone.os',
        'osds', nlist(
            escape('/var/lib/ceph/osd/sdc'), nlist(),
            'sdd', nlist(
                'journal_path', '/var/lib/ceph/log/sda4/osd-sdd/journal'
                )
            )
        ),
    'ceph002', nlist (
        'fqdn', 'ceph002.cubone.os',
        'osds', nlist(
            'sdc', nlist(
            'journal_path', '/var/lib/ceph/log/sda4/osd-sdc/journal'
            )
        )
    )
);

variable MDSS = nlist (
    'ceph002', nlist(
        'fqdn', 'ceph002.cubone.os',
        'up', true
    )
);
variable MONITOR1 =  nlist(
    'fqdn', 'ceph001.cubone.os',
    'up', true,
);
variable MONITOR2 =  nlist(
    'fqdn', 'ceph002.cubone.os',
    'up', true,
);
variable MONITOR3 =  nlist(
    'fqdn', 'ceph003.cubone.os',
    'up', true,
);

variable CONFIG = nlist (
    'fsid' , 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
    'mon_initial_members', list ('ceph001', 'ceph002', 'ceph003')
);

prefix '/software/components/ceph/clusters';

'ceph' = nlist (
    'config', CONFIG,
    'osdhosts', OSDS,
    'mdss', MDSS,
    'monitors', nlist (
        'ceph001', MONITOR1,
        'ceph002', MONITOR2,
        'ceph003', MONITOR3
    ),
    'deployhosts', nlist (
        'ceph002', 'ceph002.cubone.os'
    )

);         

'/system/network/hostname' = 'ceph003';
'/system/network/domainname' = 'cubone.os';

'/software/components/accounts/users/ceph' = 
    nlist('homeDir', '/tmp', 'gid', '111' );
'/software/components/accounts/groups/ceph' = nlist('gid', '111');
