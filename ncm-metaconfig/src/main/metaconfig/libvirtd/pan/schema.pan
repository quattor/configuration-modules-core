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

type type_qemu_vnc = {
    'vnc_listen' ? type_ip
    'vnc_auto_unix_socket' ? boolean
    'vnc_tls' ? boolean
    'vnc_tls_x509_cert_dir' ? string
    'vnc_tls_x509_verify' ? boolean
    'vnc_password' ? string
    'vnc_sasl' ? boolean
    'vnc_sasl_dir' ? string
    'vnc_allow_host_audio' ? boolean
};

type type_qemu_spice = {
    'spice_listen' ? type_ip
    'spice_tls' ? boolean
    'spice_tls_x509_cert_dir' ? string
    'spice_password' ? string
    'spice_sasl' ? boolean
    'spice_sasl_dir' ? string
};

type type_qemu_remote = {
    'remote_display_port_min' ? long(5900..65535)
    'remote_display_port_max' ? long(5900..65535)
    'remote_websocket_port_min' ? long(5700..65535)
    'remote_websocket_port_max' ? long(5700..65535)
};

type type_qemu_security = {
    'security_driver' ? string with match(SELF, '^(none|selinux|apparmor)$')
    'security_default_confined' ? boolean
    'security_require_confined' ? boolean
};

type type_qemu_cgroup = {
    'cgroup_controllers' ? string[]
    'cgroup_device_acl' ? string[]
};

function is_image_format = {
    image_format = ARGV[0];
    if(match(image_format, '^(raw|lzop|gzip|bzip2|xz)$')) return(true);
    error("Bad image format: " + image_format);
    false;
};

type type_image_format = string with is_image_format(SELF);

type type_qemu_image_format = {
    'save_image_format' ? type_image_format
    'dump_image_format' ? type_image_format
    'snapshot_image_format' ? type_image_format
};

type type_qemu_keepalive = {
    'keepalive_interval' ? long
    'keepalive_count' ? long
};

type type_qemu_migration = {
    'migration_address' ? type_ip
    'migration_host' ? type_hostname
    'migration_port_min' ? long(1..65535)
    'migration_port_max' ? long(1..65535)
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
QEMU conf for libvirtd
}
type service_qemu = {
    include type_qemu_vnc
    include type_qemu_spice
    include type_qemu_remote
    include type_qemu_security
    include type_qemu_cgroup
    include type_qemu_image_format
    include type_qemu_keepalive
    include type_qemu_migration
    'user' ? string
    'group' ? string
    'dynamic_ownership' ? boolean
    'nographics_allow_host_audio' ? boolean
    'auto_dump_path' ? string
    'auto_dump_bypass_cache' ? boolean
    'auto_start_bypass_cache' ? boolean
    'hugetlbfs_mount' ? string[]
    'bridge_helper' ? string with match(SELF, '^/')
    'clear_emulator_capabilities' ? boolean
    'set_process_name' ? boolean
    'max_processes' ? boolean
    'max_files' ? boolean
    'mac_filter' ? boolean
    'relaxed_acs_check' ? boolean
    'allow_disk_format_probing' ? boolean
    'lock_manager' ? string with match(SELF, '^(lockd|sanlock)$')
    'max_queued' ? long (0..)
    'seccomp_sandbox' ? string
    'log_timestamp' ? boolean
    'nvram' ? string[]
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


type type_kvmvm_network = {
    @{linux or OVS bridge name required by the network interface}
    'bridge' : string
    @{mac address required by the VM}
    'mac' : type_hwaddr
    @{only required to use a Open vSwitch bridge}
    'type' ? string with match (SELF, '^openvswitch$')
} = dict();

type type_kvmvm_rbd = {
    @{name of the block device available from the storage pool.
     it should include the relative path to the storage pool, as example:
     "one/disk1.vda"}
    'name' : string
    @{list of Ceph monitors}
    'ceph_hosts' : type_fqdn[]
} = dict();

@documentation{
Parameters required to use a Ceph storage backend
}
type type_kvmvm_ceph_disk = {
    @{uuid of the libvird secret generated from Ceph secret.xml file
     more info: http://docs.ceph.com/docs/master/rbd/libvirt/
     }
    'uuid' : type_uuid
    @{protocol attributes required by Ceph rados block device}
    'rbd' : type_kvmvm_rbd
    @{device assigend to the storage. Use vdx to enable virtio drivers.}
    'dev' : string with match (SELF, '^(vd[a-z]|hd[a-z])$')
    @{control cache mechanism.
     unsafe: host may cache all disk IO, and sync requests from guest are ignored}
    'cache' : string = 'none' with match (SELF, '^(none|writethrough|writeback|unsafe)$')
} = dict();

@documentation{
A graphics device allows for graphical interaction with the guest OS.
A guest will typically have either a framebuffer or a text console configured to
allow interaction with the admin.
}
type type_kvmvm_graphics = {
    @{The graphics element that should be started}
    'type' : string = 'vnc' with match (SELF, '^(vnc|spice|sdl@rdp|desktop)$')
    @{listen address to get access to the display server}
    'listen' : type_ip = '0.0.0.0'
    @{port used by the display server}
    'port' : long(5900..) = 5900
} = dict();

@documentation{
libvirt devices section
}
type type_kvmvm_devices = {
    'network' ? type_kvmvm_network[]
    'ceph_disk' ? type_kvmvm_ceph_disk[]
    'graphics' : type_kvmvm_graphics
};

@documentation{
KVM libvirt xml template that can be instantiated
by a KVM hypervisor.
}
type service_kvmvm = {
    @{name of the VM displayed by virsh command}
    'name' : type_fqdn
    @{memory required by the VM (in Mb)}
    'memory' ? long
    @{number of cpus required by the VM}
    'cpus' ? long(1..)
    @{XML devices section, it includes storage (Ceph) and network resources}
    'devices' ? type_kvmvm_devices
};
