object template basic_cluster;


variable OSDHOST2 = nlist (
    'hostname', 'ceph002', 
    'osds', nlist (
        'osd.0', nlist(
            'id', 0,
            'name', 'osd.0',
            'uuid', 'caers5d54'
                ),
        'osd.2', nlist(
            'id', 2,
            'name', 'osd.2',
            'uuid', 'caer5dds4'
                )
            )
        );
variable OSDHOST3 = nlist (
    'hostname', 'ceph003', 
    'osds', nlist (
        'osd.1', nlist(
            'id', 1,
            'name', 'osd.1',
            'uuid', 'ca3sa8354'
                ),
        'osd.3', nlist(
            'id', 3,
            'name', 'osd.3',
            'uuid', 'cas34ds4'
                )
            )
        );

variable MONITOR1 =  nlist(
    'id', 0,
    'name', 'ceph002b',
    'addr', 'ip:poort',
);
variable MONITOR2 =  nlist(
    'id', 1,
    'name', 'ceph001',
    'addr', 'ip:poort',
);
variable MONITOR3 =  nlist(
    'id', 2,
    'name', 'ceph003',
    'addr', 'ip:poort',
);

variable CONFIG = nlist (
    'fsid' , 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
    'mon_initial_members', list ('ceph001', 'ceph002', 'ceph003')
    );

prefix '/software/components/ceph/clusters';

'ceph' = nlist (
     'config', CONFIG,
     'osdhosts', nlist (
        'ceph002', OSDHOST2,
        'ceph003', OSDHOST3,
        ),
    'monitors', nlist (
        'ceph001', MONITOR2,
        'ceph002', MONITOR1,
        'ceph003', MONITOR3
    )   
);         

