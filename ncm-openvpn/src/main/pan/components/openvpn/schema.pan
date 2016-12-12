# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openvpn/schema;

include 'quattor/schema';

type structure_component_openvpn_all = {
    "configfile" : string
    "port" : type_port = 1194
    "proto" : string with match (SELF, '^(udp|tcp)$')
    "dev" : string with match (SELF, '^(tun|tap)$')
    "ca" : string
    "cert" : string
    "key" : string
    "tls-auth" ? string
    "verb" ? long(0..11)
    "cipher" : string = 'BF-CBC'
    "cd" ? string
    "ifconfig" ? string
    "tun-mtu" : long = 1500
    "comp-lzo" ? boolean = false
    "comp-noadapt" ? boolean = false
    "user" : string = "nobody"
    "group" : string = "nobody"
    "daemon" : boolean = false
    "nobind" : boolean = false
};

type structure_component_openvpn_server = {
    include structure_component_openvpn_all
    "server" ? string
    "server-bridge" ? string
    "local" ? string
    "tls-server" ? boolean = false
    "passtos" ? boolean = false
    "crl-verify" ? string
    "dh" ? string
    "tls-verify" ? string
    "push" ? string[]
    "up" ? string
    "ifconfig-pool" ? string
    "ifconfig-pool-linear" ? boolean = false
    "ifconfig-pool-persist" ? string
    "client-config-dir" ? string
    "client-to-client" ? boolean = false
    "duplicate-cn" ? boolean = false
    "max-clients" ? long
    "persist-key" ? boolean = false
    "persist-tun" ? boolean = false
    "log-append" ? string
    "management" ? string
    "topology" ? string
    "tls-remote" ? string
    "tcp-queue-limit" ? long
    "ccd-exclusive" ? boolean
    "script-security" ? long(0..3)
    "keepalive" : long[2] = list(10, 120)
    "client-connect" ? string
    "client-disconnect" ? string
};

type structure_component_openvpn_client = {
    include structure_component_openvpn_all
    "client" : boolean = false
    "remote" : string[]
    "tls-exit" ? boolean = false
    "ns-cert-type" ? string with match (SELF, '^(server|client)$')
    "persist-key" ? boolean = false
    "persist-tun" ? boolean = false
    "remote-random" ? boolean = false
    "resolv-retry" ? string
    "tls-client" : boolean = false
    "max-routes" ? long(0..)
};

type structure_component_openvpn = {
    include structure_component
    "server" ? structure_component_openvpn_server{}
    "clients" ? structure_component_openvpn_client{}
};
