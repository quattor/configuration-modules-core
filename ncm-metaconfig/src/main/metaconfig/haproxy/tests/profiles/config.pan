object template config;

include 'metaconfig/haproxy/config';

prefix '/software/components/metaconfig/services/{/etc/haproxy/haproxy.cfg}/contents';
'proxys' = append(dict());

prefix 'global';
'logs/{/dev/log}' = list('local0', 'notice');
'config/tune.ssl.default-dh-param' = 2048;
'config/chroot' = '/var/lib/haproxy';
'config/log-send-hostname' = 'haproxyhost';
'config/pidfile' = '/var/run/haproxy.pid';
'config/maxconn' = 4000;
'config/user' = 'haproxy';
'config/group' = 'haproxy';
'config/daemon' = '';
"config/ssl-default-bind-ciphers" = list('ECDHE-ECDSA-AES128-SHA256', 'ECDHE-RSA-AES128-SHA256');
"config/ssl-default-bind-options" = list('no-sslv3', 'no-tlsv10', 'no-tlsv11');
"config/ssl-default-server-ciphers" = list('ECDHE-ECDSA-AES128-SHA256', 'ECDHE-RSA-AES128-SHA256');
"config/ssl-default-server-options" = list('no-sslv3', 'no-tlsv10', 'no-tlsv11');
'stats/socket' = '/var/lib/haproxy/stats';
'logs/{127.0.0.1}' = list('local2');
prefix 'stats';
'mode' = 'http';
'options/enabled' = '';
'options/hide-version' = '';
'options/refresh' = 5;
prefix 'defaults';
'config/log' = 'global';
'config/retries' = 3;
'config/maxconn' = 4000;
'timeouts/check' = 3500;
'timeouts/queue' = 3500;
'timeouts/connect' = 3500;
'timeouts/client' = 10000;
'timeouts/server' = 10000;
'timeouts/client-fin' = 30000;
'timeouts/server-fin' = 30000;
'timeouts/tunnel' = 3600 * 1000;
'config/option' = 'tcpka';
prefix 'proxys/-1';
'name' = 'webserver';
'port' = 80;
'binds' = list('*:80');
'config/mode' = 'http';
'config/capture' = 'cookie vgnvisitor= len 32';
'config/cookie' = 'SERVERID insert indirect nocache';
'config/rspidel' = '^Set-cookie:\ IP=';
'config/balance' = 'source';
'options' = list('tcpka', 'httplog', 'httpchk', 'forwardfor', 'httpclose');
'defaultoptions' = dict(
    'inter' , 2,
    'downinter' , 5,
    'rise' , 3,
    'fall' , 2,
    'slowstart' , 60,
    'maxqueue' , 128,
    'weight' , 100,
    );
'serveroptions/cookie' = 'control';
'servers' = dict(
    'server1' , '192.168.0.11',
    'server2', '192.168.0.12',
    );

prefix 'frontends/irods-in';
"bind" = list(
    dict(
        "bind", '*',
        "port", 1247,
        "params", dict(
            "ssl", true,
            "crt", "/some/file",
            "alpn", "h2,http/1.1",
            )));
"default_backend" = "irods-bk";
"acl/network_allowed" = "src -f /etc/haproxy/whitelist.static";
"tcp-request" = list("connection reject if !network_allowed");
"http-request" = list("redirect scheme https unless { ssl_fc }");

prefix 'backends/irods-bk';
"options/0" = "tcp-check";
"tcpchecks" = list("connect", "send PING\n", 'expect string <MsgHeader_PI>\n<type>RODS_VERSION</type>');
"http-request/0" = "hello";
"acl/whatif" = "match";
"reqrep/0" = dict(
    "pattern", 'abc\ def',  # need escaped space, so single quotes
    "replace", '\1 \2',
    );
"reqrep/1" = dict(
    "pattern", 'ghi\ jkl',
    "replace", '\3 \4',
    );
"servers/0" = dict('name', 'localhost', 'ip', '127.0.0.1', 'port', 1247);
"servers/1" = dict('name', 'other.host', 'ip', '10.20.30.1', 'params', dict('ssl', true, 'ca-file', '/other/file'));
"servers/2" = dict('name', 'othername', 'ip', '10.20.30.1', 'port', 1247, 'params', dict('check', true, 'port', 1247, 'inter', 1234));

prefix 'backends/sshproxy';
"balance" = 'leastconn';
"stick" = "on src";
"options/0" = 'tcp-check';
"tcpchecks" = list('expect string SSH-2.0-');
"httpcheck" = dict(
    'inverse', true,
    'match', 'status',
    'pattern', '404',
    );
"sticktable" = dict(
    'type', 'ip',
    'size', '1m',
    'peers', 'mypeers');

'servers/0' = dict('name', 'othername', 'ip', '10.20.30.1', 'port', 1247, 'params', dict('check', true, 'port', 1247));

prefix 'peers';
'mypeers/peers' = list(dict('name', 'testhost', 'ip', '10.20.30.4', 'port', 1024));
