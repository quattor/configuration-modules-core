unique template metaconfig/slurm/topology;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/topology.conf}/contents" = slurm_topology_conf;

prefix "/software/components/metaconfig/services/{/etc/slurm/topology.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/topology";
"daemons/slurmd" = "restart";
