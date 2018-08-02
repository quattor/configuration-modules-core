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
'contents/proxys/' = append(
    dict('name' , 'webserver',
        'port' , 80,
        'binds' , list('*:'+to_string(80)),
        'config' , dict(
            'mode' , 'http',
            'capture' , 'cookie vgnvisitor= len 32',
            'cookie' , 'SERVERID insert indirect nocache',
            'rspidel' , '^Set-cookie:\ IP=',
            'balance' , 'source',
        ),
        'options' , list('tcpka','httplog','httpchk','forwardfor','httpclose'),
        'defaultoptions' , dict(
            'inter' , 2,
            'downinter' , 5,
            'rise' , 3,
            'fall' , 2,
            'slowstart' , 60,
            'maxqueue' , 128,
            'weight' , 100,
        ),
        'serveroptions', dict(
            'cookie', 'control',
        ),
        'servers' , dict(
            'server1' , '192.168.0.11',
            'server2','192.168.0.12'
        ),
    )
);
'contents/global/logs/{127.0.0.1}' = list('local2');

prefix 'contents/frontends/irods-in';
"bind" = '*:1247';
"default_backend" = "servers";

prefix 'contents/backends/servers';
"options/0" = "tcp-check";
"tcpchecks" = list("connect", "send PING\n", 'expect string <MsgHeader_PI>\n<type>RODS_VERSION</type>');
"servers/0" = dict('name', 'localhost', 'ip', '127.0.0.1', 'port', 1247);
"servers/1" = dict('name', 'otherhost.test.com', 'ip', '10.20.30.1', 'check_port', 1247);
"servers/2" = dict('name', 'othername', 'ip', '10.20.30.1', 'port', 1247, 'check_port', 1247);

