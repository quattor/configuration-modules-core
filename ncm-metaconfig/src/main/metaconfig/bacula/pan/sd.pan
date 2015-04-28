unique template metaconfig/bacula/sd;

include 'metaconfig/bacula/schema';

bind "/software/components/metaconfig/services/{/etc/bacula/bacula-sd.conf}/contents" = bacula_config;

prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-sd.conf}";
"daemons/bacula-sd" = "restart";
"module" = "bacula/main";
"mode" = 0640;


