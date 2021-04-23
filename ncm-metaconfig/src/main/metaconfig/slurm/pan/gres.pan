unique template metaconfig/slurm/gres;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/gres.conf}/contents" = slurm_gres_conf;

prefix "/software/components/metaconfig/services/{/etc/slurm/gres.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/gres";
"daemons/slurmd" = "restart";
