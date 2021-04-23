unique template metaconfig/slurm/job_container;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/job_container.conf}/contents" = slurm_job_container_conf;

prefix "/software/components/metaconfig/services/{/etc/slurm/job_container.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/gres";
"convert/truefalse" = true;
"daemons/slurmd" = "restart";
