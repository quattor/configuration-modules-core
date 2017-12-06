object template client_allopts;

include 'metaconfig/openvpn/client_config';

prefix "/software/components/metaconfig/services/{/etc/openvpn/client.conf}/contents";

"ca" = "/etc/pki/CA/certs/cabundle.pem";
"cert" = "/etc/openvpn/certs/vpn.crt";
"cipher" = "AES-256-CBC";
"client" = true;
"comp-lzo" = true;
"dev" = "tun";
"group" = "nobody";
"key" = "/etc/openvpn/keys/vpn.key";
"max-routes" = 150;
"persist-key" = true;
"persist-tun" = true;
"port" = 1194;
"proto" = "tcp";
"remote" = list(
    "vpntest.domain.example 1194",
    "fallbackvpntest.domain.example 1195"
    );
"resolv-retry" = "infinite";
"tls-auth" = "/etc/openvpn/vpntest/ta.key 1";
"tun-mtu" = 1500;
"user" = "nobody";
"verb" = 3;
"tls-exit" = true;
"remote-cert-tls" = "client";
"persist-key" = true;
"persist-tun" = true;
"remote-random" = true;
"tls-client" = true;
"cd" = "/openvpnhome/";
"ifconfig" = "l rn";
"comp-noadapt" = true;
"daemon" = true;
"nobind" = true;
