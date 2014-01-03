object template basic_cluster;


variable OSDS = nlist (
    'osd.0', nlist(
        'id', 0,
        'host', 'ceph002', 
        'name', 'osd.0',
    ),
    'osd.2', nlist(
        'id', 2,
        'host', 'ceph002', 
        'name', 'osd.2',
    ),
    'osd.1', nlist(
        'id', 1,
        'host', 'ceph003', 
        'name', 'osd.1',
    ),
    'osd.3', nlist(
        'id', 3,
        'host', 'ceph003', 
        'name', 'osd.3',
    )
);

variable MONITOR1 =  nlist(
    'name', 'ceph002',
    'up', true,
);
variable MONITOR2 =  nlist(
    'name', 'ceph001',
    'up', true,
);
variable MONITOR3 =  nlist(
    'name', 'ceph003',
    'up', false,
);

variable CONFIG = nlist (
    'fsid' , 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
    'mon_initial_members', list ('ceph001', 'ceph002', 'ceph003')
);

prefix '/software/components/ceph/clusters';

'ceph' = nlist (
    'config', CONFIG,
    'osds', OSDS,
    'monitors', nlist (
        'ceph001', MONITOR2,
        'ceph002', MONITOR1,
        'ceph003', MONITOR3
    )   
);         

