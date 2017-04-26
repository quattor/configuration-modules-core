object template server_config;

include 'metaconfig/openvpn/server_config';

prefix "/software/components/metaconfig/services/{/etc/openvpn/server.conf}/contents";

"ca" = "/etc/pki/CA/certs/cabundle.pem";
"cert" = "/etc/openvpn/cert/vpn.crt";
"cipher" = "AES-256-CBC";
"comp-lzo" = true;
"dev" = "tun";
"dh" = "/etc/openvpn/dh/dh-4096.pem";
"group" = "nobody";
"ifconfig-pool-persist" = "ipp.txt";
"keepalive" = list(10, 120);
"key" = "/etc/openvpn/keys/vpn.key";
"log-append" = "/var/log/openvpn.log";
"max-clients" = 10;
"persist-key" = true;
"persist-tun" = true;
"port" = 1194;
"proto" = "tcp";
"server" = "10.10.0.0 255.255.0.0";
"tls-auth" = "/etc/openvpn/keys/ta.key 0";
"tun-mtu" = 1500;
"user" = "nobody";
"verb" = 4;
"push" = list(
    "route 11.2.1.0 255.255.255.0",
    "route 10.3.1.0 255.255.255.0",
    "route 9.1.1.0 255.255.255.0"
    );
