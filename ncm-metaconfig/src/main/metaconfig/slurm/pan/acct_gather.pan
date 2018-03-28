unique template metaconfig/slurm/acct_gather;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/acct_gather.conf}/contents" = slurm_acct_gather_conf;

variable SLURM_DAEMONS = {
    if(is_defined(SLURM_MASTER) && SLURM_MASTER) { SELF["slurmctld"] = "restart"; };
    if(is_defined(SLURM_WORKER) && SLURM_WORKER) { SELF["slurmd"] = "restart"; };
    SELF;
};

prefix "/software/components/metaconfig/services/{/etc/slurm/acct_gather.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/acct_gather";
"daemons" = if(length(SLURM_DAEMONS) > 0) SLURM_DAEMONS else null;
