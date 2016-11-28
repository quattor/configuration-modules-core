unique template metaconfig/singularity/config;

include 'metaconfig/singularity/schema';

bind "/software/components/metaconfig/services/{/etc/singularity/singularity.conf}/contents" = service_singularity;

prefix "/software/components/metaconfig/services/{/etc/singularity/singularity.conf}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"module" = "singularity/main";
