object template gres;

function pkg_repl = { null; };
include 'metaconfig/slurm/gres';
'/software/components/metaconfig/dependencies' = null;

prefix "/software/components/metaconfig/services/{/etc/slurm/gres.conf}/contents";
'Default' = dict(
    'AutoDetect', 'off',
);
'Nodes' = list(
    dict(
        'NodeName', list('node001', 'node005'),
        'AutoDetect', 'nvml',
    ),
    dict(
        'NodeName', list('node002'),
        'AutoDetect', 'off',
        'Name', 'mps',
        'File', '/dev/nvidia[0-3]',
        'Type', 'TeslaP100',
    ),
    dict(
        'NodeName', list('node003'),
        'Name', 'mps',
        'File', '/dev/nvidia1',
        'Count', 100,
        'Cores', list(2, 4),
        'Flags', list('CountOnly'),
    ),
);
