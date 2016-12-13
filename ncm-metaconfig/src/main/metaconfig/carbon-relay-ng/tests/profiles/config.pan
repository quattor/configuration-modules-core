object template config;

include 'metaconfig/carbon-relay-ng/config';

prefix "/software/components/metaconfig/services/{/etc/carbon-relay-ng.ini}/contents";
'instance' = 'mydefault';
'listen_addr' = "1.2.3.4:2003";
'admin_addr' = "5.6.7.8:2004";
'http_addr' = "localhost.localdomain:8081";
'spool_dir' = "/var/spool/carbon-relay-ng";
'log_level' = "info";
'instrumentation/graphite_addr' = "9.8.7.6:1234";
'instrumentation/graphite_interval' = 1234;
# recreate the example
'init/0/addBlack/match' = "filter-out-all-metrics-matching-this-substring";
'init/1/addRoute' = dict(
    'type', 'sendAllMatch',
    'key', 'carbon-default',
    'dest', list(dict(
        'addr', '127.0.0.1:2005',
        'opts', dict(
            'spool', true,
            'pickle', false,
            ),
        )),
    );
'init/2/addRoute' = dict(
    'type', 'sendAllMatch',
    'key', 'carbon-tagger',
    'opts', dict(
        'sub', '=',
        ),
    'dest', list(dict(
        'addr', '127.0.0.1:2006',
        )),
    );
'init/3/addRoute' = dict(
    'type', 'sendFirstMatch',
    'key', 'analytics',
    'opts', dict(
        'regex', '(Err/s|wait_time|logger)',
        ),
    'dest', list(
        dict(
            'addr', 'graphite.prod:2003',
            'opts', dict(
                'prefix', 'prod.',
                'spool', true,
                'pickle', true,
                )),
        dict(
            'addr', 'graphite.staging:2003',
            'opts', dict(
                'prefix', 'staging.',
                'spool', true,
                'pickle', true,
                )),
        ),
    );
