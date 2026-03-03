@{
    unbound - Schema
}

declaration template metaconfig/unbound/schema;

include 'pan/types';
include 'quattor/types/component';

type structure_unbound_server = {
    'verbosity' : long
    'statistics-interval' : long
    'statistics-cumulative' : string = 'no'
    'extended-statistics' ? string = 'yes'
    'num-threads' : long
    'interface' : string
    'interface-automatic' : string = 'no'
    'outgoing-interface' ? string
    'port' ? long
    'outgoing-range' ? long
    'msg-cache-size' ? string
    'msg-cache-slabs' ? long
    'num-queries-per-thread' ? long
    'rrset-cache-size'  ? string = '200m'
    'rrset-cache-slabs' ? long
    'infra-cache-slabs' ? long
    'do-ip4' ? choice ('no', 'yes')
    'do-ip6' ? choice ('no', 'yes')
    'do-udp' ? choice ('no', 'yes')
    'do-tcp' ? choice ('no', 'yes')
    'do-daemonize' ? string = 'no'
    'chroot' : string = 'yes'
    'username' ? string
    'directory' ? string = '/etc/unbound'
    'use-syslog' : choice ('no', 'yes')
    'pidfile' ? string
    'root-hints' ? string
    'harden-glue' ? string = 'yes'
    'harden-dnssec-stripped' ? choice ('no', 'yes')
    'harden-referral-path' ? choice ('no', 'yes')
    'use-caps-for-id' ? choice ('no', 'yes')
    'unwanted-reply-threshold' ? long
    'val-clean-additional' ? choice ('no', 'yes')
    'val-permissive-mode' ? choice ('no', 'yes')
    'key-cache-slabs' ? long
    'log-queries' ? string
    'tcp-upstream' ? choice ('no', 'yes')
    'ssl-upstream' ? choice ('no', 'yes')
    'ssl-service-key' ? string
    'ssl-service-pem' ? string
    'ssl-port' ? long
    'auto-trust-anchor-file' ? string
    'incoming-num-tcp' ? long(0..)
    'infra-cache-min-rtt' ? long(0..)
    'infra-cache-max-rtt' ? long(0..)
    'infra-keep-probing' ? choice('no', 'yes')
    'ip-ratelimit' ? long(0..)
    'prefetch' ? choice('no', 'yes')
    'prefetch-key' ? choice('no', 'yes')
    'rrset-roundrobin' ? choice('no', 'yes')
    'trust-anchor' ? string
    'trust-anchor-file' ? string
    'trusted-keys-file' ? string
    'unblock-lan-zones' ? choice('no', 'yes')
    'module-config' ?  string
    'do-not-query-localhost' ? choice('no', 'yes')
};

type structure_unbound_local_zone = {
    'nodefault' : list
    'static' : list
    'redirect' ? string[]
};

type structure_unbound_forward_zone = {
    'forward_addr' ? list
    'name' ? list
};

type structure_unbound_odc_forward_zone = {
    'forward_addr' : string[]
    'name' : string[]
};

type structure_unbound_sp_forward_zone = {
    'forward_addr' ? string[]
    'forward_host' ? string[]
    'name' : string[]
};

type structure_unbound_stub_zone = {
    'addrs' : string[]
    'names' : string[]
};

type structure_unbound_remote_control = {
    'control-enable' : string with match (SELF, 'yes|no')
    'control-interface' : string = '127.0.0.1'
    'control-port' ? long
    'server-key-file' ? string = 'unbound_server.key'
    'server-cert-file' ? string = 'unbound_server.pem'
    'control-key-file' ? string = 'unbound_control.key'
    'control-cert-file' ? string = 'unbound_server.key'
};

type structure_unbound_access_control = {
    'deny' ? list
    'allow' ? list
    'allow_snoop' ? list
};

@{
desc = Represent the unbound.conf configuration file. See unbound.conf(5) for details of the keys and values.
}
type structure_unbound = {
    'server' : structure_unbound_server
    'access_control' ? structure_unbound_access_control
    'local_zone' ? structure_unbound_local_zone
    'forward_zone' ? structure_unbound_forward_zone
    'odc_forward_zone' ? structure_unbound_odc_forward_zone[]
    'sp_forward_zone' ? structure_unbound_sp_forward_zone[]
    'stub_zones' ? structure_unbound_stub_zone[]
    'local_data' ? list
    'remote_control' : structure_unbound_remote_control
    'default_forwarders' ? list
};
