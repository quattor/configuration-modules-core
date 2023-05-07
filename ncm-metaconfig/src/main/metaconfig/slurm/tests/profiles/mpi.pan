object template mpi;

function pkg_repl = { null; };
include 'metaconfig/slurm/mpi';
'/software/components/metaconfig/dependencies' = null;

prefix "/software/components/metaconfig/services/{/etc/slurm/mpi.conf}/contents";
'PMIxCollFence' = 'mixed';
'PMIxDebug' = false;
'PMIxEnv' = list('ABC', 'FOO');
