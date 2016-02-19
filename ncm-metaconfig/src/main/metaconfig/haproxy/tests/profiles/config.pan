object template config;

include 'metaconfig/haproxy/config';

prefix '/software/components/metaconfig/services/{/etc/haproxy/haproxy.cfg}';
'contents/global/logs/{/dev/log}' = list('local0','notice');
'contents/global/config/tune.ssl.default-dh-param' = 2048;
'contents/global/config/chroot' = '/var/lib/haproxy';
'contents/global/config/pidfile' = '/var/run/haproxy.pid';
'contents/global/config/maxconn' = 4000;
'contents/global/config/user' = 'haproxy';
'contents/global/config/group' = 'haproxy';
'contents/global/config/daemon' = '';
'contents/global/stats/socket' = '/var/lib/haproxy/stats';
'contents/stats/mode' = 'http';
'contents/stats/options/enabled' = '';
'contents/stats/options/hide-version' = '';
'contents/stats/options/refresh' = 5;
'contents/defaults/config/log' = 'global';
'contents/defaults/config/retries' = 3;
'contents/defaults/config/maxconn' = 4000;
'contents/defaults/timeouts/check' = 3500;
'contents/defaults/timeouts/queue' = 3500;
'contents/defaults/timeouts/connect' = 3500;
'contents/defaults/timeouts/client' = 10000;
'contents/defaults/timeouts/server' = 10000;
'contents/proxys/' = append(dict('name' , 'webserver',
    'port' , 80,
    'binds' , list('*:'+to_string(80)),
    'config' , dict(
        'mode' , 'http',
        'capture','cookie vgnvisitor= len 32',
        'cookie', 'SERVERID insert indirect nocache',
        'rspidel', '^Set-cookie:\ IP=',
        'balance' , 'source',),
    'options' , list('tcpka','httplog','httpchk','forwardfor','httpclose'),
    'defaultoptions',dict(
        'inter', 2,
        'downinter', 5,
        'rise', 3,
        'fall', 2,
        'slowstart', 60,
        'maxqueue', 128,
        'weight', 100,),
    'serveroptions',dict(
       'cookie','control',
    ),
    'servers', dict('server1','192.168.0.11','server2','192.168.0.12'),)
);

