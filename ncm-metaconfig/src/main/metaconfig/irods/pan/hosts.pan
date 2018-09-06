unique template metaconfig/irods/hosts;

include 'metaconfig/irods/config';

bind "/software/components/metaconfig/services/{/etc/irods/hosts_config.json}/contents" = irods_hosts_config;

prefix "/software/components/metaconfig/services/{/etc/irods/hosts_config.json}";
"module" = "jsonpretty";
"daemons/irods" = "restart";
"owner" = "irods";
"group" = "irods";
