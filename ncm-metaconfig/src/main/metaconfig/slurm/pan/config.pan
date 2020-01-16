unique template metaconfig/slurm/config;

@{when defined, indicate this is a master. when false, this is a node.
  leave undef when this is e.g. a loginnode}
variable SLURM_IS_MASTER ?= undef;
final variable SLURM_CONFIG_DAEMON = if (is_defined(SLURM_IS_MASTER) && SLURM_IS_MASTER) 'slurmctld' else 'slurmd';

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}/contents" = slurm_conf;

variable SLURM_DAEMONS = {
    if(is_defined(SLURM_MASTER) && SLURM_MASTER) { SELF["slurmctld"] = "restart"; };
    if(is_defined(SLURM_WORKER) && SLURM_WORKER) { SELF["slurmd"] = "restart"; };
    SELF;
};

prefix "/software/components/metaconfig/services/{/etc/slurm/slurm.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/config";
"convert/unescapekey" = true;
"daemons" = if(length(SLURM_DAEMONS) > 0) SLURM_DAEMONS else null;
