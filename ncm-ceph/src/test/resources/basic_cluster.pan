object template basic_cluster;


variable osdhost2 = nlist (
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
variable osdhost3 = nlist (
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

variable monitor1 =  nlist(
    'id', 0,
    'name', 'ceph002b',
    'addr', 'ip:poort',
);
variable monitor2 =  nlist(
    'id', 1,
    'name', 'ceph001',
    'addr', 'ip:poort',
);
variable monitor3 =  nlist(
    'id', 2,
    'name', 'ceph003',
    'addr', 'ip:poort',
);

variable config = nlist (
    'fsid' , 'a94f9906-ff68-487d-8193-23ad04c1b5c4',
    'mon_initial_members', list ('ceph001', 'ceph002', 'ceph003')
    );

prefix '/software/components/ceph/clusters';

'ceph1' = nlist (
     'config', config,
     'osdhosts', nlist (
        'ceph002', osdhost2,
        'ceph003', osdhost3,
        ),
    'monitors', nlist (
        'ceph001', monitor2,
        'ceph002', monitor1,
        'ceph003', monitor3
    )   
);         

