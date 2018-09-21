unique template metaconfig/irods/server_config;

include 'metaconfig/irods/schema';

bind "/software/components/metaconfig/services/{/var/lib/irods/.irods/irods_environment.json}/contents" =
    irods_environment_server_config;
prefix "/software/components/metaconfig/services/{/var/lib/irods/.irods/irods_environment.json}";
"module" = "jsonpretty";
"daemons/irods" = "restart";
"owner" = "irods";
"group" = "irods";

