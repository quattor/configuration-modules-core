unique template metaconfig/mlocate/config;

include 'metaconfig/mlocate/schema';

bind "/software/components/metaconfig/services/{/etc/updatedb.conf}/contents" = config_updatedb;

prefix "/software/components/metaconfig/services/{/etc/updatedb.conf}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"module" = "mlocate/updatedb";
