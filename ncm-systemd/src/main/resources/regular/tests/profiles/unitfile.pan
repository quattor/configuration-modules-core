unique template unitfile;

include 'components/systemd/schema';

bind "/unitfile" = systemd_unitfile_config[];

"/unitfile/0" = dict(
    'includes', list(
        '/unit/1',
        '/unit/2',
        ),
    'unit', dict(
        'Assert', dict(
            'PathExists', list(
                '', # reset
                '/path/1',
                '/path/2',
                ),
            ),
        'Condition', dict(
            'PathExists', list(
                '', # reset
                '/path/C1',
                '/path/C2',
                ),
            ),
        'Description', 'my test',
        'Requires', list('unit1', 'unit2'),
        'After', list('unit0', 'unit01'),
        'Before', list('unita', 'unitb'),
        ),
    'service', dict(
        'CPUAffinity', list(
            list(), # reset
            list(1, 2, 3, 4),
        ),
        'Environment', list(
            dict(
                'VAR1-1', 'val1-1 val1-1b',
                'VAR1-2', 'val1-2',
                ),
            dict(
                'VAR2-1', 'val2-1',
                'VAR2-2', 'val2-2 val2-2b',
                ),
            ),
        'EnvironmentFile', list(
            '/envfile/1',
            '/envfile/2',
            ),
        'ExecStart', '/usr/bin/special',
        'TTYReset', true,
        'TTYVHangup', false,
        'LimitSTACK', -1,
        'LimitNPROC', 100,
        'RuntimeDirectory', list('foo/bar', 'tmp'),
        'RuntimeDirectoryMode', '0777',
        'RuntimeDirectoryPreserve', 'restart',
        'MemoryAccounting', true,
        'MemoryLimit', 1024,
        'BlockIODeviceWeight', list(list('/var', '100'), list('/tmp', '50')),
        ),
    'socket', dict(
        'ExecStartPre', list('/some/path arg1', '-/some/other/path arg2'),
        'ListenStream', list('/path/to/pipe'),
        'SocketUser', 'pipeuser',
        'SocketGroup', 'pipegroup',
        'SocketMode', '660',
        ),
    'mount', dict(
        'What', 'server:/share',
        'Where', '/data/share',
        'Type', 'glusterfs',
        'Options', list('_netdev', 'defaults'),
        'DirectoryMode', '0750',
        ),
    'install', dict(
        'WantedBy', list('1.service', '2.service'),
        ),
    );
