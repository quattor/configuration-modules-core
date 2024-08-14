declaration template metaconfig/slurm/schema;

variable METACONFIG_SLURM_VERSION ?= '24.05';

@{include version specific types at the end}
include format('metaconfig/slurm/schema_%s', METACONFIG_SLURM_VERSION);
