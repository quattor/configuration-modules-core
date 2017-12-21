template tcfgfile;

include 'components/ceph/v2/schema';

'/software/components/ceph/ceph_version' = '12.2.2';

prefix '/software/components/ceph/config';
"global" = dict(
    'mon_host', list('host1.aaa.be', 'host2.aaa.be', 'host3.aaa.be'),
    'mon_initial_members', list('host1', 'host2', 'host3'),
    'public_network', '192.168.0.0/20',
    'fsid', '8c09a56c-5859-4bc0-8584-d2c2232d62f6', 
);
"osd" = dict(
    'osd_max_scrubs', 4,
);
'rgw/client.rgw.test' = dict(
    'host', 'host3', 
    'keyring', 'keyfile',
    'rgw_dns_name', 'host3.aaa.be');
