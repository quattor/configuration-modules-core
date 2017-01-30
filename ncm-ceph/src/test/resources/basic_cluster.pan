object template basic_cluster;


variable OSDS = dict (
    'ceph001', dict (
        'fqdn', 'ceph001.cubone.os',
        'osds', dict(
            escape('/var/lib/ceph/osd/sdc'), dict(),
            'sdd', dict(
                'journal_path', '/var/lib/ceph/log/sda4/osd-sdd/journal'
                )
            )
        ),
    'ceph002', dict (
        'fqdn', 'ceph002.cubone.os',
        'osds', dict(
            'sdc', dict(
            'journal_path', '/var/lib/ceph/log/sda4/osd-sdc/journal'
            )
        )
    )
);

variable MDSS = dict (
    'ceph002', dict(
        'fqdn', 'ceph002.cubone.os',
        'up', true
    )
);
variable MONITOR1 =  dict(
    'fqdn', 'ceph001.cubone.os',
    'up', true,
);
variable MONITOR2 =  dict(
    'fqdn', 'ceph002.cubone.os',
    'up', true,
);
variable MONITOR3 =  dict(
    'fqdn', 'ceph003.cubone.os',
    'up', true,
);

variable CONFIG = dict (
    'fsid' , 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
    'mon_initial_members', list ('ceph001', 'ceph002', 'ceph003')
);

prefix '/software/components/ceph/clusters';

'ceph' = dict (
    'config', CONFIG,
    'osdhosts', OSDS,
    'mdss', MDSS,
    'monitors', dict (
        'ceph001', MONITOR1,
        'ceph002', MONITOR2,
        'ceph003', MONITOR3
    ),
    'deployhosts', dict (
        'ceph002', 'ceph002.cubone.os'
    )

);

'/software/components/ceph/ssh_multiplex' = true;
'/software/components/ceph/max_add_osd_failures_per_host' = 1;
'/system/network/hostname' = 'ceph003';
'/system/network/domainname' = 'cubone.os';

'/software/components/accounts/users/ceph' =
    dict('homeDir', '/tmp', 'gid', '111' );
'/software/components/accounts/groups/ceph' = dict('gid', '111');
