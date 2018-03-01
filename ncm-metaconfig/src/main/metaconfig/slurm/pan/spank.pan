unique template metaconfig/slurm/spank;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/plugstack.conf}/contents" = slurm_spank_conf;

prefix "/software/components/metaconfig/services/{/etc/slurm/plugstack.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/spank";
"daemons/slurmd" = "restart";
