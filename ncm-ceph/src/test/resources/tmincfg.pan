template tmincfg;

include 'components/ceph/v2/schema';
bind '/software/components/ceph' = ceph_component;

prefix '/software/components/ceph/minconfig';
"global" = dict(
    'mon_host', list('host1.aaa.be', 'host2.aaa.be', 'host3.aaa.be'),
    'fsid', '8c09a56c-5859-4bc0-8584-d2c2232d62f6',
);
