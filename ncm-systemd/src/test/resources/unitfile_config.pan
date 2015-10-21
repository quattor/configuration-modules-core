object template unitfile_config;

include 'components/systemd/schema';

bind "/software/components/systemd/unit" = systemd_unit_type{};

prefix "/software/components/systemd/unit";
"{regular.service}/file" = nlist(
    'only', true,
    'config', nlist(
        'unit', nlist(
            'AssertPathExists', list(
                '', # reset
                '/path/1',
                '/path/2',
                ),
            ),
        'service', nlist(
            'CPUAffinity', list(list(), list(0,1)),
            ),
        ),
    );

"{replace.service}/file" = nlist(
    'only', true,
    'replace', true,
    'config', nlist(
        'includes', list(
            '/unit/1',
            '/unit/2',
            ),
        ),
    );
