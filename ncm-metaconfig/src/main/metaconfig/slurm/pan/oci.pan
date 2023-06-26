unique template metaconfig/slurm/oci;

include 'components/metaconfig/config';
include 'metaconfig/slurm/schema';

bind "/software/components/metaconfig/services/{/etc/slurm/oci.conf}/contents" = slurm_oci_conf;

prefix "/software/components/metaconfig/services/{/etc/slurm/oci.conf}";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "slurm/oci";
"daemons/slurmd" = "restart";
