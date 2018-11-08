object template config;

include 'metaconfig/irods/config';

bind "/software/components/metaconfig/services/{/etc/nagios/irods/irods_environment.conf}/contents" = irods_environment_client_config;

prefix "/software/components/metaconfig/services/{/etc/nagios/irods/irods_environment.conf}";
"module" = "jsonpretty";

prefix "/software/components/metaconfig/services/{/etc/nagios/irods/irods_environment.conf}/contents";

"irods_host" = "iicat01.example.org";
"irods_port" = 1247;
"irods_user_name" = "nagios";
"irods_zone_name" = "UGent";

