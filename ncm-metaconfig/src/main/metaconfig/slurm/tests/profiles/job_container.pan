object template job_container;

function pkg_repl = { null; };
include 'metaconfig/slurm/job_container';
'/software/components/metaconfig/dependencies' = null;

prefix "/software/components/metaconfig/services/{/etc/slurm/job_container.conf}/contents";
'Default' = dict(
    'AutoBasePath', true,
    'Basepath', '/var/tmp/slurm',
    'Dirs', list('/tmp', '/dev/shm'),
);
'Nodes' = list(
    dict(
        'AutoBasePath', true,
        'Basepath', '/tmp/slurm',
        'NodeName', list('node001', 'node005'),
    ),
);
