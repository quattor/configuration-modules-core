unique template metaconfig/openvpn/server_config;

include 'metaconfig/openvpn/schema';

bind "/software/components/metaconfig/services/{/etc/openvpn/server.conf}/contents" = config_openvpn_server;

prefix "/software/components/metaconfig/services/{/etc/openvpn/server.conf}";
"module" = "openvpn/config";
