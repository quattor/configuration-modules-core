declaration template metaconfig/libvirtd/schema;

include 'pan/types';

type type_libvirtd_network = {
    'listen_tls' ? boolean = true # enabled by default
    'listen_tcp' ? boolean = false # disabled by default
    'tls_port' ? type_port = 16514 # port (16514) or service name
    'tcp_port' ? type_port = 16509 # port (16509) or service name
    'listen_addr' ? type_hostname # IPv4/v6 or hostname
    'mdns_adv' ? boolean = true # enabled by default
    'mdns_name' ? string # default "Virtualization Host HOSTNAME"
};

type type_libvirtd_socket = {
    'unix_sock_group' ? string # restricted to root by default
    'unix_sock_ro_perms' ? string # default allows any user
    'unix_sock_rw_perms' ? string
    'unix_sock_dir' ? string # directory of created sockets
};

type type_auth_unix_libvirtd = string with match(SELF,'^(none|sasl|polkit)$');
type type_auth_libvirtd = string with match(SELF,'^(none|sasl)$');

type type_libvirtd_authn = {
    'auth_unix_ro' ? type_auth_unix_libvirtd # default anyone
    'auth_unix_rw' ? type_auth_unix_libvirtd # default polkit
    'auth_tcp' ? type_auth_libvirtd # should be 'sasl' for production
    'auth_tls' ? type_auth_libvirtd
    'access_drivers' ? string[]
};

type type_libvirtd_tls = {
    'key_file' ? string
    'cert_file' ? string
    'ca_file' ? string
    'crl_file' ? string
};

type type_libvirtd_authz = {
    'tls_no_verify_certificate' ? boolean # defaults to verification
    'tls_no_sanity_certificate' ? boolean
    'tls_allowed_dn_list' ? string[]
    'sasl_allowed_username_list' ? string[]
};

type type_libvirtd_processing = {
    'max_clients' ? long(1..)
    'min_workers' ? long(1..)
    'max_workers' ? long(1..)
    'max_requests' ? long(1..)
    'max_client_requests' ? long(1..)
    'max_queued_clients' ? long(1..)
    'max_anonymous_clients' ? long(1..)
    'prio_workers' ? long(1..)
};

type type_libvirtd_logging = {
    'log_level' ? long(0..4) # 4=errors,3=warnings,2=info,1=debug,0=none
    'log_filters' ? string # see man for format
    'log_outputs' ? string # see man for format
};

type type_libvirtd_keepalive = {
    'keepalive_interval' ? long (1..)
    'keepalive_count' ? long (1..)
    'keepalive_required' ? boolean
};

type type_libvirtd_audit = {
    'audit_level' ? long (0..2)
    'audit_logging' ? boolean
};

@documentation{
libvirtd.conf settings
}
type service_libvirtd = {
    include type_libvirtd_network
    include type_libvirtd_socket
    include type_libvirtd_authn
    include type_libvirtd_tls
    include type_libvirtd_authz
    include type_libvirtd_processing
    include type_libvirtd_logging
    include type_libvirtd_keepalive
    include type_libvirtd_audit
    # standalone ones
    'host_uuid' ? type_uuid
};

@documentation{
sasl2 conf for libvirtd
}
type service_sasl2 = {
    'mech_list' ? string with match(SELF, '^(digest-md5|gssapi)$')
    'keytab' ? string = '/etc/libvirt/krb5.tab'
    'sasldb_path' ? string = '/etc/libvirt/passwd.db'
};

@documentation{
Override the default config file
NOTE: This setting is no longer honoured if using
systemd. Set '--config /etc/libvirt/libvirtd.conf'
}
type service_sysconfig_libvirtd = {
    'libvirtd_config' ? string = '/etc/libvirt/libvirtd.conf'
    'libvirtd_args' ? string with match(SELF, '^(--listen)$')
    'krb5_ktname' ? string = '/etc/libvirt/krb5.tab'
    'qemu_audio_drv' ? string with match(SELF, '^(sdl)$')
    'sdl_audiodriver' ? string with match(SELF, '^(pulse)$')
    'libvirtd_nofiles_limit' ? long (1..)
};


type type_kvmvm_network {
    'bridge' : string
    'mac' : type_hwaddr
    'type' ? string = 'bridge' with match (SELF, '^(bridge|openvswitch)$')
} = dict();

type type_kvmvm_ceph_storage {
    'uuid' : type_uuid
} = dict();

type type_kvmvm_devices = {
    'network' ? type_kvmvm_network
    'storage' ? type_kvmvm_ceph_storage
} = dict();

@documentation{
KVM libvirt template to be instantiated
during hypervisor boot time
}
type service_kvmvm = {
    'name' : type_fqdn
    'memory' ? long
    'cpus' ? long(1..)
    'devices' ? type_kvmvm_devices
};
