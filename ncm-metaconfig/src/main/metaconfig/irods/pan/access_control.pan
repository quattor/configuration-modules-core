unique template metaconfig/irods/access_control;

include 'metaconfig/irods/config';

bind "/software/components/metaconfig/services/{/etc/irods/host_access_control_config.json}/contents" =
    irods_host_access_control_config;

prefix "/software/components/metaconfig/services/{/etc/irods/host_access_control_config.json}";
"module" = "jsonpretty";
"daemons/irods" = "restart";
"owner" = "irods";
"group" = "irods";
