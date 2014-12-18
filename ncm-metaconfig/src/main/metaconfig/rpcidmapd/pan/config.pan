unique template metaconfig/rpcidmapd/config;

include 'metaconfig/rpcidmapd/schema';

bind "/software/components/metaconfig/services/{/etc/idmapd.conf}/contents" = rpcidmapd_config;

prefix "/software/components/metaconfig/services/{/etc/idmapd.conf}";
"daemon/0" = "rpcidmapd";
"module" = "rpcidmapd/main";

