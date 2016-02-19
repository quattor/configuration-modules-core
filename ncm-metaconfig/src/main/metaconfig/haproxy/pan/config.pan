unique template metaconfig/haproxy/config;

include 'metaconfig/haproxy/schema';

bind "/software/components/metaconfig/services/{/etc/haproxy/haproxy.cfg}/contents" = haproxy_service;

prefix "/software/components/metaconfig/services/{/etc/haproxy/haproxy.cfg}";
"daemons" = dict(
    "haproxy", "restart",
);
"module" = "haproxy/main";
