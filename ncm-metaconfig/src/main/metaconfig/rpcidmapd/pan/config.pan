unique template metaconfig/rpcidmapd/config;

include 'metaconfig/rpcidmapd/schema';

# RPCIDMAPD_SERVICE_PREFIX
# on EL7.1+: use "nfs-";
# on EL7.0 there's a nfs-idmap.service (without 'd'), but also the default
# on EL6.X: use "rpc" (the default)
variable RPCIDMAPD_SERVICE_PREFIX ?= "rpc";
final variable RPCIDMAPD_SERVICE = format("%sidmapd", RPCIDMAPD_SERVICE_PREFIX);

bind "/software/components/metaconfig/services/{/etc/idmapd.conf}/contents" = rpcidmapd_config;

prefix "/software/components/metaconfig/services/{/etc/idmapd.conf}";
"daemons" = {
    SELF[RPCIDMAPD_SERVICE] = "restart";
    SELF;
};
"module" = "rpcidmapd/main";

