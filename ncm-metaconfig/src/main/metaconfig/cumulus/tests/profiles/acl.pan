object template acl;

include 'metaconfig/cumulus/acl';

prefix "/software/components/metaconfig/services/{/etc/cumulus/acl/policy.d/50_quattor.rules}/contents";
"iptables/0" = dict(
    'append', 'FORWARD',
    'jump', 'ACCEPT',
    'in-interface', list('swp1'),
    'protocol', 'tcp',
    'dport', list(80, 90),  # range
    );
"iptables/1" = dict(
    'append', 'INPUT',
    'jump', 'DROP',
    'out-interface', list('swp3', 'swp4'),
    'protocol', 'tcp',
    'source', list('1.2.3.0/24'),
    'sport', list(100),  # 1 port
    'tcp-flags', dict(  # --syn
        'mask', list('SYN', 'ACK', 'FIN', 'RST'),
        'compare', list('SYN'),
        ),
    'invert', dict(
        'source', true,
        'sport', true,
        'out-interface', true,
        ),
    );
