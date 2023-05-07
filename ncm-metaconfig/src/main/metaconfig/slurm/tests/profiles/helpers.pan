object template helpers;

function pkg_repl = { null; };
include 'metaconfig/slurm/helpers';
'/software/components/metaconfig/dependencies' = null;

prefix "/software/components/metaconfig/services/{/etc/slurm/helpers.conf}/contents";
'ExecTime' = 10;
'Default' = dict(
    'Feature', list('a'),
    'Helper', '/bin/foo',
);
'Nodes' = list(
    dict(
        'NodeName', list('node001', 'node005'),
        'Feature', list('b'),
        'Helper', '/bin/bar',
    ),
);
