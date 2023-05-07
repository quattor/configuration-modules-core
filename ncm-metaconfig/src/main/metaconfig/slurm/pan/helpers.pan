unique template metaconfig/slurm/helpers;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/helpers.conf}/contents" = slurm_helpers_conf;

prefix "/software/components/metaconfig/services/{/etc/slurm/helpers.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/helpers";
"daemons/slurmd" = "restart";
