unique template metaconfig/cachefilesd/config;

include 'metaconfig/cachefilesd/schema';

bind "/software/components/metaconfig/services/{/etc/cachefilesd.conf}/contents" = cachefilesd_service;

prefix "/software/components/metaconfig/services/{/etc/cachefilesd.conf}";
"daemons/cachefilesd" = "restart";
"module" = "cachefilesd/main";
"mode" = 0644;
