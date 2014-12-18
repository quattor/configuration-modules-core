unique template metaconfig/ctdb/config;

include 'metaconfig/ctdb/schema';

bind "/software/components/metaconfig/services/{/etc/sysconfig/ctdb}/contents/service" = ctdb_service;

prefix "/software/components/metaconfig/services/{/etc/sysconfig/ctdb}";
"daemon/0" = "ctdb";
"module" = "ctdb/sysconfig";
