unique template metaconfig/zkrsync/config;

include 'metaconfig/zkrsync/schema';

bind "/software/components/metaconfig/services/{/etc/zkrs/default.conf}/contents" = zkrsync_config;

prefix "/software/components/metaconfig/services/{/etc/zkrs/default.conf}";
"module" = "zkrsync/main";

