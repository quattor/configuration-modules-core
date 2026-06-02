declaration template metaconfig/slurm/schema;

variable METACONFIG_SLURM_VERSION ?= '25.11';

@{include version specific types at the end}
include format('metaconfig/slurm/schema_%s', METACONFIG_SLURM_VERSION);
