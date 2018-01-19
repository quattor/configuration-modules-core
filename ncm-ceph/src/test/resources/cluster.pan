object template cluster;

variable MDSS = dict (
    'ceph002', dict(
        'fqdn', 'ceph002.cubone.os',
    )   
);
variable MONITOR1 =  dict(
    'fqdn', 'ceph001.cubone.os',
);
variable MONITOR2 =  dict(
    'fqdn', 'ceph002.cubone.os',
);
variable MONITOR3 =  dict(
    'fqdn', 'ceph003.cubone.os',
);

include 'components/ceph/v2/schema';

'/software/components/ceph/ceph_version' = '12.2.2';


prefix '/software/components/ceph/cluster';

'mdss' = MDSS;
'monitors' = dict (
    'ceph001', MONITOR1,
    'ceph002', MONITOR2,
    'ceph003', MONITOR3
);
'deployhosts' = dict (
    'ceph002', 'ceph002.cubone.os'
);
'ssh_multiplex' = true;

prefix '/software/components/ceph/cluster/initcfg';
"global" = dict(
    'mon_host', list('host1.aaa.be', 'host2.aaa.be', 'host3.aaa.be'),
    'mon_initial_members', list('host1', 'host2', 'host3'),
    'public_network', '192.168.0.0/20',
    'fsid', '8c09a56c-5859-4bc0-8584-d2c2232d62f6', 
);

'/system/network/hostname' = 'ceph002';
'/system/network/domainname' = 'cubone.os';

'/software/components/accounts/users/ceph' =
    dict('homeDir', '/tmp', 'gid', '167' );
'/software/components/accounts/groups/ceph' = dict('gid', '167');

