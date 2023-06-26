declaration template metaconfig/slurm/schema;

variable METACONFIG_SLURM_VERSION ?= '23.02';

@{include version specific types at the end}
include format('metaconfig/slurm/schema_%s', METACONFIG_SLURM_VERSION);
