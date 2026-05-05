object template config;

include 'metaconfig/unbound/config';

'/software/components/metaconfig/services/{/etc/unbound/unbound.conf}' = {
    server = dict(
        'verbosity', 1,
        'statistics-interval', 0,
        'incoming-num-tcp', 10,
        'statistics-cumulative', 'no',
        'extended-statistics', 'no',
        'num-threads', 2,
        'interface-automatic', 'no',
        'interface', '127.0.0.1',
        'prefetch', 'yes',
        'rrset-roundrobin', 'yes',
        'trusted-keys-file', '""',
        'trust-anchor-file', '""',
        'trust-anchor', '""',
        'auto-trust-anchor-file', '""',
        'module-config', 'iterator',
        'use-syslog', 'yes',
        'chroot', '""',
        'root-hints', '""',
        'unblock-lan-zones', 'yes',
        'ip-ratelimit', 1000,
    );
    remote_control = dict(
        'control-interface', '/run/unbound/unbound-remote-control.sock',
        'control-enable', 'no',
    );
    dict(
        'module', 'unbound/unbound',
        'owner', 'root',
        'group', 'root',
        'backup', '.old',
        'mode', 0644,
        'daemons', dict('unbound', 'restart'),
        'contents', dict(
            'server', server,
            'remote_control', remote_control,
            'forward_zone', dict(
                'name', list('.'),
                'forward_addr', list("10.100.111.112", "10.100.111.113"),
            ),
        ),
    );
};
