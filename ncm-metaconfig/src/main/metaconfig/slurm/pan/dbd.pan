unique template metaconfig/slurm/dbd;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/slurmdbd.conf}/contents" = slurm_dbd_conf;

prefix "/software/components/metaconfig/services/{/etc/slurm/slurmdbd.conf}";
"owner" = "slurm";
"group" = "slurm";
"mode" = 0600;
"module" = "slurm/dbd";
"daemons/slurmdbd" = "restart";
