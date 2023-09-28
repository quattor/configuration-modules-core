object template config;

include 'metaconfig/telegraf/config';

prefix "/software/components/metaconfig/services/{/etc/telegraf/telegraf.conf}/contents";

'global_tags' = dict(
    'model', 'test_model',
    'personality', 'test_personality',
);

'agent' = dict(
    'interval', '60s',
    'round_interval', true,
    'metric_buffer_limit', 5000,
    'collection_jitter', '0s',
    'flush_interval', '300s',
    'flush_jitter', '60s',
    'debug', false,
    'quiet', false,
    'omit_hostname', false,
);

'inputs/cpu' = list(
    dict(
        'percpu', false,
        'totalcpu', true,
        'fielddrop', list(
            'time_*',
        ),
        'tagdrop', dict(
            'cpu', list(
                'cpu6',
                'cpu7',
            ),
        ),
    ),
);

'inputs/disk' = list(
    dict(
        'mount_points', list(
            '/',
            '/pool',
        ),
        'ignore_fs', list(
            'tmpfs',
            'devtmpfs',
        ),
        'tagpass', dict(
            'fstype', list(
                'ext4',
                'xfs',
            ),
            'path', list(
                '/opt',
                '/home*',
            ),
        ),
    ),
);

'outputs' = dict(
    'influxdb', list(
        dict(
            'urls', list(
                'http://influxdb01.example.org:8086',
            ),
            'database', 'testnodes',
            'precision', 's',
            'timeout', '5s',
            'username', 'write_testnodes',
            'password', 'test_password',
            'skip_database_creation', true,
        ),
    ),
);
