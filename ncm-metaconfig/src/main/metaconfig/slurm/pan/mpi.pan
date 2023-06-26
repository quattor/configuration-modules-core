unique template metaconfig/slurm/mpi;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/mpi.conf}/contents" = slurm_mpi_conf;

prefix "/software/components/metaconfig/services/{/etc/slurm/mpi.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/acct_gather";
"daemons/slurmd" = "restart";
