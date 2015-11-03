unique template unitfile;

include 'components/systemd/schema';

bind "/unitfile" = systemd_unitfile_config[];

"/unitfile/0" = nlist(
    'includes', list(
        '/unit/1',
        '/unit/2',
        ),
    'unit', nlist(
        'Assert', nlist(
            'PathExists', list(
                '', # reset
                '/path/1',
                '/path/2',
                ),
            ),
        'Condition', nlist(
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
    'service', nlist(
        'CPUAffinity', list(
            list(), # reset
            list(1, 2, 3, 4),
        ),
        'Environment', list(
            nlist(
                'VAR1-1', 'val1-1 val1-1b',
                'VAR1-2', 'val1-2',
                ),
            nlist(
                'VAR2-1', 'val2-1',
                'VAR2-2', 'val2-2 val2-2b',
                ),
            ),
        'EnvironmentFile', list(
            '/envfile/1',
            '/envfile/2',
            ),
        'TTYReset', true,
        'TTYVHangup', false,
        ),
    'install', nlist(
        'WantedBy', list('1.service', '2.service'),
        ),
    );
