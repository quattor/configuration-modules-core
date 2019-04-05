object template server_config;

include 'metaconfig/irods/server_config';

prefix "/software/components/metaconfig/services/{/var/lib/irods/.irods/irods_environment.json}/contents";

"irods_host" = "iicat01.example.org";
"irods_port" = 1247;
"irods_user_name" = "nagios";
"irods_zone_name" = "UGent";
"irods_home" = "/UGent/home/rods";
"irods_cwd" = "/UGent/home/rods";
"irods_server_control_plane_key" = "AAAAAAAAAAAVALETESTUDIA";

