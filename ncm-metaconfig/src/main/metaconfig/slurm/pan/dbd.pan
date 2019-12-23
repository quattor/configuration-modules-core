unique template metaconfig/slurm/dbd;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/slurmdbd.conf}/contents" = slurm_dbd_conf;

prefix "/software/components/metaconfig/services/{/etc/slurm/slurmdbd.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/dbd";
"daemons/slurmdbd" = "restart";
