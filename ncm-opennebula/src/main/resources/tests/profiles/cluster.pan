object template cluster;

include 'components/opennebula/schema';

bind "/metaconfig/contents/cluster/red.cluster" = opennebula_cluster;

"/metaconfig/module" = "cluster";

prefix "/metaconfig/contents/cluster/red.cluster";
"reserved_cpu" = 10;
"reserved_mem" = 2097152;
"labels" = list("quattor", "quattor/VO");
"description" = "red.cluster managed by quattor";
