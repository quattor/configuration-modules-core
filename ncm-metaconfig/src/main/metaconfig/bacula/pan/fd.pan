unique template metaconfig/bacula/fd;

include 'metaconfig/bacula/schema';

bind "/software/components/metaconfig/services/{/etc/bacula/bacula-fd.conf}/contents" = bacula_config;

prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-fd.conf}";
"daemon/0" = "bacula-fd";
"module" = "bacula/main";
"mode" = 0640;

