object template labeled_crushmap;



'/system/network/hostname' = 'ceph003';
'/system/network/domainname' = 'cubone.os';

'/software/components/accounts/users/ceph' =  nlist('homeDir', '/tmp', 'gid', '111' );
'/software/components/accounts/groups/ceph' = nlist('gid', '111');

variable CEPH_HOSTS = list('ceph001', 'ceph002', 'ceph003');
variable CEPH_OSD_DISKS = list('sdc','sdd','sde','sdf','sdg','sdh','sdi','sdj','sdk','sdl','sdm','sdn');
variable CEPH_JOURNAL_DISKS = list('sda4','sdb');
variable CEPH_DEFAULT_OSD_WEIGHT = 1.0;

variable MDSS = nlist (
    'ceph001.cubone.os', nlist(
        'fqdn', 'ceph001.cubone.os',
        ),
    'ceph002.cubone.os', nlist(
        'fqdn', 'ceph002.cubone.os',
    )
);
variable MONITOR1 =  nlist(
    'up', true,
    'fqdn', 'ceph001.cubone.os',
);
variable MONITOR2 =  nlist(
    'up', true,
    'fqdn', 'ceph002.cubone.os',
);
variable MONITOR3 =  nlist(
    'up', false,
    'fqdn', 'ceph003.cubone.os',
);

variable CONFIG = nlist (
    'fsid' , '82766e04-585b-49a6-a0ac-c13d9ffd0a7d',
    'mon_initial_members', list ('ceph001', 'ceph002', 'ceph003'),
    'public_network', '10.141.8.0/20',
    'cluster_network', '10.143.8.0/20',
    'osd_pool_default_size', 3,
    'osd_pool_default_min_size', 2,
    'osd_pool_default_pg_num', 400,
    'osd_pool_default_pgp_num', 400, 
);

prefix '/software/components/ceph';
'ceph_version'   =  '0.72.2';
'deploy_version' = '1.3.5';

prefix '/software/components/ceph/clusters/ceph';

'crushmap' = nlist(
    'types' , list('osd','host','root'),
    'rules', list (
        nlist(
            'name', 'data',
            'type', 'replicated',
            'min_size', 0,
            'max_size', 10,
            'steps', list(
                nlist(
                    'take', 'default', 
                    'choices', list(
                        nlist(
                            'chtype', 'chooseleaf firstn',
                            'bktype', 'host',
                            'number', 0,
                        ),
                    ),
                ),
            ),
        ),
        nlist(
            'name', 'metadata',
            'type', 'replicated',
            'min_size', 0,
            'max_size', 10,
            'steps', list(
                nlist(
                    'take', 'default', 
                    'choices', list(
                        nlist(
                            'chtype', 'chooseleaf firstn',
                            'bktype', 'host',
                            'number', 0,
                        ),
                    ),
                ),
            ),
        ),
        nlist(
            'name', 'rbd',
            'type', 'replicated',
            'min_size', 0,
            'max_size', 10,
            'steps', list(
                nlist(
                    'take', 'default', 
                    'choices', list(
                        nlist(
                            'chtype', 'chooseleaf firstn',
                            'bktype', 'host',
                            'number', 0,
                        ),
                    ),
                ),
            ),
        ),
    ),
    'buckets', list(
        nlist(
            'name', 'default',
            'type', 'root',
            'defaultalg', 'straw',
            'defaulthash', 0,
            'labels', list('tst-0', 'tst-1'), 
            'buckets', list(
                nlist(
                    'name', 'ceph001',
                    'type', 'host',
                ),
                nlist(
                    'name', 'ceph002',
                    'type', 'host',
                ),
                nlist(
                    'name', 'ceph003',
                    'type', 'host',
                ),
            ),
        ),
    ),
);
'config' = CONFIG;
'osdhosts' = {
    t=nlist();    
    foreach(idx;host;CEPH_HOSTS) {
        d = nlist();
        foreach(odx;disk;CEPH_OSD_DISKS) {
            jdx= odx % length(CEPH_JOURNAL_DISKS); ## RR over journal disks
            d[disk] = nlist(
                'journal_path', format('/var/lib/ceph/log/%s/osd-%s/journal', CEPH_JOURNAL_DISKS[jdx], disk),
                'crush_weight', CEPH_DEFAULT_OSD_WEIGHT,
                'labels', list(format('tst-%s', jdx))
            );
        };
        t[host] = nlist(
            'fqdn', format('%s.%s', host, value('/system/network/domainname')),
            'osds', d
        );
    };
    t;
};

'mdss' = MDSS;
'monitors' = nlist (
    'ceph001', MONITOR1,
    'ceph002', MONITOR2,
    'ceph003', MONITOR3
);
'deployhosts' = nlist (
    'ceph001', 'ceph001.cubone.os',
);  
