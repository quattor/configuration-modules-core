# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openvpn/schema;

include {'quattor/schema'};

type structure_component_openvpn_server = {
    "configfile"        : string
    "server"            ? string
    "server-bridge"	? string
    "port"              : port = 1194
    "proto"             : string with match (SELF, 'udp|tcp')
    "dev"               : string with match (SELF, 'tun|tap')
    "ca"                : string
    "cert"              : string
    "key"               : string
    "local"		? string
    "tun-mtu"           ? long = 1500
    "comp-lzo"          ? boolean = false
    "comp-noadapt"      ? boolean = false
    "tls-server"        ? boolean = false
    "tls-auth"		? string
    "passtos"           ? boolean = false
    "keepalive"		? string = "10 120"
    "crl-verify"	? string
    "dh"		? string
    "tls-verify"	? string
    "push"		? string[]
    "up"		? string
    "ifconfig-pool"	? string
    "ifconfig-pool-linear" ? boolean = false
    "ifconfig-pool-persist" ? string
    "client-config-dir" ? string
    "client-to-client"  ? boolean = false
    "duplicate-cn"      ? boolean = false
    "max-clients"	? long
    "user"		? string = "nobody"
    "group"		? string = "nobody"
    "daemon"		? boolean = false
    "nobind"            ? boolean = false
    "persist-key"       ? boolean = false
    "persist-tun"       ? boolean = false
    "log-append"	? string
    "verb"              ? long(0..11)
    "management"	? string
    "topology"		? string
};

type structure_component_openvpn_client = {
    "configfile"        : string
    "client"	        : boolean = false
    "port"              : port = 1194
    "remote"            : string[]
    "proto"      	: string with match (SELF, 'udp|tcp')
    "dev"     		: string with match (SELF, 'tun|tap')
    "ca"		: string
    "cert"		: string
    "key"		: string
    "tls-auth"		? string
    "tls-exit"		? boolean = false
    "ns-cert-type" 	? string with match (SELF, 'server|client')
    "tun-mtu"     	? long = 1500
    "comp-lzo"		? boolean = false
    "comp-noadapt"	? boolean = false
    "nobind"		? boolean = false
    "persist-key"	? boolean = false
    "persist-tun"	? boolean = false
    "remote-random"	? boolean = false
    "resolv-retry"	? string
    "verb"		? long(0..11)
};

type structure_component_openvpn = {
    include structure_component
    "server"            ? structure_component_openvpn_server
    "client"            ? structure_component_openvpn_client
};

bind "/software/components/openvpn" = structure_component_openvpn;
