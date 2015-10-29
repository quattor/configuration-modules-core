declaration template metaconfig/libvirtd/schema;

include 'pan/types';

type structure_libvirtd_network = {
    'listen_tls' ? boolean = true # enabled by default
    'listen_tcp' ? boolean = false # disabled by default
    'tls_port' ? type_port # port (16514) or service name
    'tcp_port' ? type_port # port (16509) or service name
    'listen_addr' ? type_hostname # IPv4/v6 or hostname
    'mdns_adv' ? boolean = true # enabled by default
    'mdns_name' ? string # default "Virtualization Host HOSTNAME"
};

type structure_libvirtd_socket = {
    'unix_sock_group' ? string # restricted to root by default
    'unix_sock_ro_perms' ? string # default allows any user
    'unix_sock_rw_perms' ? string 
    'unix_sock_dir' ? string # directory of created sockets
};

type structure_libvirtd_authn = {
    'auth_unix_ro' ? string with match(SELF, 'none|sasl|polkit') # default anyone
    'auth_unix_rw' ? string with match(SELF, 'none|sasl|polkit') # default polkit
    'auth_tcp' ? string with match(SELF, 'none|sasl') # should be 'sasl' for production
    'auth_tls' ? string with match(SELF, 'none|sasl') 
    'access_drivers' ? string[]
};

type structure_libvirtd_tls = {
    'key_file' ? string
    'cert_file' ? string
    'ca_file' ? string
    'crl_file' ? string
};

type structure_libvirtd_authz = {
    'tls_no_verify_certificate' ? boolean # defaults to verification
    'tls_no_sanity_certificate' ? boolean
    'tls_allowed_dn_list' ? string[]
    'sasl_allowed_username_list' ? string[]
};

type structure_libvirtd_processing = {
    'max_clients' ? long(1..)
    'min_workers' ? long(1..)
    'max_workers' ? long(1..)
    'max_requests' ? long(1..)
    'max_client_requests' ? long(1..)
    'max_queued_clients' ? long(1..)
    'max_anonymous_clients' ? long(1..)
    'prio_workers' ? long(1..)
};

type structure_libvirtd_logging = {
    'log_level' ? long(0..4) # 4=errors,3=warnings,2=info,1=debug,0=none
    'log_filters' ? string # see man for format
    'log_outputs' ? string # see man for format
};

type structure_libvirtd_keepalive = {
    'keepalive_interval' ? long (1..)
    'keepalive_count' ? long (1..)
    'keepalive_required' ? boolean
};

type structure_libvirtd_audit = {
    'audit_level' ? long (0..2)
    'audit_logging' ? boolean
};

type structure_component_libvirtd = {
    'network' ? structure_libvirtd_network
    'socket' ? structure_libvirtd_socket
    'authn' ? structure_libvirtd_authn
    'tls' ? structure_libvirtd_tls
    'authz' ? structure_libvirtd_authz
    'processing' ? structure_libvirtd_processing
    'logging' ? structure_libvirtd_logging
    'keepalive' ? structure_libvirtd_keepalive
    'audit' ? structure_libvirtd_audit
    'host_uuid' ? type_uuid
};
