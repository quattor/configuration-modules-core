object template config;

include 'metaconfig/keepalived/config';

prefix '/software/components/metaconfig/services/{/etc/keepalived/keepalived.conf}';
'contents/global_defs/router_id'='vm1';
'contents/vrrp_scripts'=append(
    dict(
        'name' , 'haproxy',
        'script' , '"killall -0 haproxy"',
        'interval' , 2,
        'weight' , 2
    )
);
'contents/vrrp_instances'=append(
    dict(
        'name' , 'Testing',
        'config' , dict(
            'virtual_router_id' , 52,
            'advert_int' , 1,
            'priority' , 100,
            'state' , 'BACKUP',
            'interface' , 'eth0',
        ),
        'virtual_ipaddresses' , list(
            dict(
                'ipaddress' , '192.168.1.20',
                'interface' , 'eth0',
            ),
        ),
        'track_scripts' , list('haproxy'),
    )
); 
