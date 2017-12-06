object template server_allopts;

include 'metaconfig/openvpn/server_config';

prefix "/software/components/metaconfig/services/{/etc/openvpn/server.conf}/contents";

"ca" = "/etc/pki/CA/certs/cabundle.pem";
"ccd-exclusive" = true;
"cd" = "../";
"cert" = "/etc/openvpn/cert/vpn.crt";
"cipher" = "AES-256-CBC";
"client-config-dir" = "/etc/openvpn/client/";
"client-connect" = "ls -ahl";
"client-disconnect" = "echo bye bye";
"client-to-client" = true;
"comp-lzo" = true;
"comp-noadapt" = true;
"crl-verify" = "/etc/";
"daemon" = true;
"dev" = "tun";
"dh" = "/etc/openvpn/dh/dh-4096.pem";
"duplicate-cn" = true;
"group" = "nobody";
"ifconfig" = "l rn";
"ifconfig-pool" = "10.8.0.4 10.8.0.251";
"ifconfig-pool-linear" = true;
"ifconfig-pool-persist" = "ipp.txt";
"keepalive" = list(10, 120);
"key" = "/etc/openvpn/keys/vpn.key";
"local" = "mynewhostname";
"log-append" = "/var/log/openvpn.log";
"management" = "10.0.0.1 21";
"max-clients" = 10;
"nobind" = true;
"passtos" = true;
"persist-key" = true;
"persist-tun" = true;
"port" = 1194;
"proto" = "tcp";
"push" = list(
    "route 11.2.1.0 255.255.255.0",
    "route 10.3.1.0 255.255.255.0",
    "route 9.1.1.0 255.255.255.0"
    );
"script-security" = 3;
"server" = "10.10.0.0 255.255.0.0";
"server-bridge" = "10.8.0.4 255.255.255.0 10.8.0.128 10.8.0.254";
"tcp-queue-limit" = 64;
"tls-auth" = "/etc/openvpn/keys/ta.key 0";
"tls-server" = true;
"tls-verify" = "/bin/tls-verify";
"topology" = "net30";
"tun-mtu" = 1500;
"up" = "some_command";
"user" = "nobody";
"verb" = 4;
