object template ipv4;

prefix '/software/components/hostsfile';

'active' = true;
'file' = '/tmp/hosts.local';
'entries' = dict(
    'priv_1', dict(
        'ipaddr', '192.168.42.1',
        'comment', 'Private One',
    ),
    'priv_2', dict(
        'ipaddr', '192.168.42.2',
        'comment', 'Private Two',
    ),
    'priv_3', dict(
        'ipaddr', '192.168.42.3',
        'comment', 'Private Three',
    ),
);
