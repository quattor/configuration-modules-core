# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/libvirtd/schema;

include 'quattor/schema';

include 'pan/types';

type structure_libvirtd_network = {
    'listen_tls' ? long(0..1) # enabled by default
    'listen_tcp' ? long(0..1) # disabled by default
    'tls_port' ? string # port (16514) or service name
    'tcp_port' ? string # port (16509) or service name
    'listen_addr' ? type_hostname # IPv4/v6 or hostname
    'mdns_adv' ? long(0..1) # enabled by default
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
};

type structure_libvirtd_tls = {
    'key_file' ? string
    'cert_file' ? string
    'ca_file' ? string
    'crl_file' ? string
};

type structure_libvirtd_authz = {
    'tls_no_verify_certificate' ? long(0..1) # defaults to verification
    'tls_allowed_dn_list' ? string[]
    'sasl_allowed_username_list' ? string[]
};

type structure_libvirtd_processing = {
    'max_clients' ? long(1..)
    'min_workers' ? long(1..)
    'max_workers' ? long(1..)
    'max_requests' ? long(1..)
    'max_client_requests' ? long(1..)
};

type structure_libvirtd_logging = {
    'log_level' ? long(0..4) # 4=errors,3=warnings,2=info,1=debug,0=none
    'log_filters' ? string[] # see man for format
    'log_outputs' ? string[] # see man for format
};

type structure_component_libvirtd = {
    include structure_component
    'libvirtd_config' : string = '/etc/libvirt/libvirtd.conf'
    'network' ? structure_libvirtd_network
    'socket' ? structure_libvirtd_socket
    'authn' ? structure_libvirtd_authn
    'tls' ? structure_libvirtd_tls
    'authz' ? structure_libvirtd_authz
    'processing' ? structure_libvirtd_processing
    'logging' ? structure_libvirtd_logging
};

bind '/software/components/libvirtd' = structure_component_libvirtd;
