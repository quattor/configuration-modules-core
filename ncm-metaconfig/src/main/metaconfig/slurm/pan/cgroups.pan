unique template metaconfig/slurm/cgroups;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/cgroup.conf}/contents" = slurm_cgroups_conf;

prefix "/software/components/metaconfig/services/{/etc/slurm/cgroup.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/dbd";
"daemons/slurmd" = "restart";
