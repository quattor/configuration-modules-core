object template config;

include 'metaconfig/keepalived/config';

prefix '/software/components/metaconfig/services/{/etc/keepalived/keepalived.conf}';
'contents/global_defs/router_id' = 'vm1';
'contents/vrrp_scripts' = append(
    dict(
        'name', 'haproxy',
        'script', '"killall -0 haproxy"',
        'interval', 2,
        'weight', 2
    )
);
'contents/vrrp_instances' = append(
    dict(
        'name', 'Testing',
        'config', dict(
            'virtual_router_id', 52,
            'advert_int', 1,
            'priority', 100,
            'state', 'BACKUP',
            'interface', 'eth0',
        ),
        'virtual_ipaddresses', list(
            dict(
                'ipaddress', '192.168.1.20',
                'interface', 'eth0',
                'broadcast', '192.168.0.255',
            ),
        ),
        'track_scripts', list('haproxy'),
    )
);
'contents/vrrp_instances' = append(
    dict(
        'name', 'Testmore',
        'config', dict(
            'virtual_router_id', 53,
            'state', 'BACKUP',
            'interface', 'eth0',
        ),
        'virtual_ipaddresses', list(
            dict(
                'ipaddress', '192.168.1.21',
                'interface', 'eth0',
            ),
        ),
    )
);

'contents/vrrp_sync_groups' = dict('Testgroup',
    dict(
        'group', list('I1', 'I2'),
        'notify_master', dict(
            'script', '/run/this/script',
            'args', list('master'),
        ),
        'notify_backup', dict(
            'script', '/run/this/script',
            'args', list('backup'),
        ),
        'notify_fault', dict(
            'script', '/run/this/script',
            'args', list('fault'),
        ),
    )
);

