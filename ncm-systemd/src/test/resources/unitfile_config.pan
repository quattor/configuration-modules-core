object template unitfile_config;

include 'components/systemd/schema';
include 'components/systemd/functions';

bind "/software/components/systemd/unit" = systemd_unit_type{};

prefix "/software/components/systemd/unit";
"{regular.service}/file" = dict(
    'only', true,
    'config', dict(
        'unit', dict(
            'Assert', dict(
                'PathExists', list(
                    '', # reset
                    '/path/1',
                    '/path/2',
                    ),
                ),
            'RequiresMountsFor', list("/x/y/z"),
            'After', list(systemd_make_mountunit("/g/h/i/")),
            ),
        'service', dict(
            'CPUAffinity', list(list(), list(0,1)),
            ),
        ),
    );

"{replace.service}/file" = dict(
    'only', true,
    'replace', true,
    'config', dict(
        'includes', list(
            '/unit/1',
            '/unit/2',
            ),
        ),
    );
