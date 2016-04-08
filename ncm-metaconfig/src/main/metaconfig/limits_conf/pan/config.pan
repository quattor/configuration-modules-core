unique template metaconfig/limits_conf/config;

include 'metaconfig/limits_conf/schema';

bind "/software/components/metaconfig/services/{/etc/security/limits.d/91-quattor.conf}/contents" = limits_conf_file;

prefix "/software/components/metaconfig/services/{/etc/security/limits.d/91-quattor.conf}";
"module" = "limits_conf/main";
