unique template metaconfig/opennebula/config;

include 'metaconfig/opennebula/schema';

bind "/software/components/metaconfig/services/{/etc/aii/opennebula.conf}/contents" = aii_opennebula_conf;

prefix "/software/components/metaconfig/services/{/etc/aii/opennebula.conf}";
"mode" = 0600;
"owner" = "root";
"group" = "root";
"module" = "tiny";
