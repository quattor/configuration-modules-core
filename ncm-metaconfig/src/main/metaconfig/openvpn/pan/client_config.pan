unique template metaconfig/openvpn/client_config;

include 'metaconfig/openvpn/schema';

bind "/software/components/metaconfig/services/{/etc/openvpn/client.conf}/contents" = config_openvpn_client;

prefix "/software/components/metaconfig/services/{/etc/openvpn/client.conf}";
"module" = "openvpn/config";
