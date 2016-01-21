object template comment;

prefix '/software/components/iptables/';

# Accept all connections from private address range
'filter/rules' = list(
    dict(
        'command', '-A',
        'chain', 'input',
        'source', '10.0.0.0/8',
        'jump', 'ACCEPT',
        'comment', 'Private IP space',
    ),
    dict(
        'command', '-A',
        'chain', 'input',
        'source', '172.16.0.0/16',
        'jump', 'ACCEPT',
        'comment', 'Internal',
    ),
);
