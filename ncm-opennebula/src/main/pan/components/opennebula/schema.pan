# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/opennebula/schema;

include 'quattor/schema';
include 'pan/types';

type directory = string with match(SELF,'[^/]+/?$');

type opennebula_mysql_db = {
    "server" ? string
    "port" ? long(0..)
    "user" ? string
    "passwd" ? string
    "db_name" ? string
};

type opennebula_db = {
    include opennebula_mysql_db
    "backend" : string with match(SELF, "^(mysql|sqlite)$")
} with is_consistent_database(SELF);

@documentation{ 
check if a specific type of database has the right attributes
}
function is_consistent_database = {
    db = ARGV[0];
    if (db['backend'] == 'mysql') {
        req = list('server', 'port', 'user', 'passwd', 'db_name');
        foreach(idx; attr; req) {
            if(!exists(db[attr])) {
                error(format("Invalid mysql db! Expected '%s' ", attr));
                return(false);
            };
        };
    };
    return(true);
};

type opennebula_log = {
    "system" : string = 'file' with match (SELF, '^(file|syslog)$')
    "debug_level" : long(0..3) = 3
} = dict();

type opennebula_federation = {
    "mode" : string = 'STANDALONE' with match (SELF, '^(STANDALONE|MASTER|SLAVE)$')
    "zone_id" : long = 0
    "master_oned" : string = ''
} = dict();

type opennebula_im = {
    "executable" : string = 'one_im_ssh'
    "arguments" : string
    "sunstone_name" ? string
} = dict();

type opennebula_im_mad_collectd = {
    include opennebula_im
} = dict("executable", 'collectd', "arguments", '-p 4124 -f 5 -t 50 -i 20');

type opennebula_im_mad_kvm = {
    include opennebula_im
} = dict("arguments", '-r 3 -t 15 kvm', "sunstone_name", 'KVM');

type opennebula_im_mad_xen = {
    include opennebula_im
} = dict("arguments", '-r 3 -t 15 xen4', "sunstone_name", 'XEN');

type opennebula_im_mad = {
    "collectd" : opennebula_im_mad_collectd
    "kvm" : opennebula_im_mad_kvm
    "xen" ? opennebula_im_mad_xen
} = dict();

type opennebula_vm = {
    "executable" : string = 'one_vmm_exec'
    "arguments" : string
    "default" : string
    "sunstone_name" : string
    "imported_vms_actions" : string[] = list(
        'terminate',
        'terminate-hard',
        'hold',
        'release',
        'suspend',
        'resume',
        'delete',
        'reboot',
        'reboot-hard',
        'resched',
        'unresched',
        'disk-attach',
        'disk-detach',
        'nic-attach',
        'nic-detach',
        'snap-create',
        'snap-delete',
    )
    "keep_snapshots" : boolean = false
} = dict();

type opennebula_vm_mad_kvm = {
    include opennebula_vm
} = dict("arguments", '-t 15 -r 0 kvm', "default", 'vmm_exec/vmm_exec_kvm.conf', "sunstone_name", 'KVM');

type opennebula_vm_mad_xen = {
    include opennebula_vm
} = dict("arguments", '-t 15 -r 0 xen4', "default", 'vmm_exec/vmm_exec_xen4.conf');

type opennebula_vm_mad = {
    "kvm" : opennebula_vm_mad_kvm
    "xen" ? opennebula_vm_mad_xen
} = dict();

type opennebula_tm_mad = {
    "executable" : string = 'one_tm'
    "arguments" : string = '-t 15 -d dummy,lvm,shared,fs_lvm,qcow2,ssh,ceph,dev,vcenter,iscsi_libvirt'
} = dict();

type opennebula_datastore_mad = {
    "executable" : string = 'one_datastore'
    "arguments" : string  = '-t 15 -d dummy,fs,vmfs,lvm,ceph'
} = dict();

type opennebula_hm_mad = {
    "executable" : string = 'one_hm'
} = dict();

type opennebula_auth_mad = {
    "executable" : string = 'one_auth_mad'
    "authn" : string = 'ssh,x509,ldap,server_cipher,server_x509'
} = dict();

type opennebula_tm_mad_conf = {
    "name" : string = "dummy"
    "ln_target" : string = "NONE"
    "clone_target" : string = "SYSTEM"
    "shared" : boolean = true
    "ds_migrate" ? boolean
} = dict();

@documentation{
The  configuration for each driver is defined in DS_MAD_CONF.
These values are used when creating a new datastore and should not be modified
since they defined the datastore behavior.
}
type opennebula_ds_mad_conf = {
    @{name of the transfer driver, listed in the -d option of the DS_MAD section}
    "name" : string = "dummy"
    @{comma separated list of required attributes in the DS template}
    "required_attrs" : string[] = list('')
    @{specifies whether the datastore can only manage persistent images}
    "persistent_only" : boolean = false
    "marketplace_actions" ? string
} = dict();

@documentation{
The  configuration for each driver is defined in MARKET_MAD_CONF.
These values are used when creating a new marketplace and should not be modified
since they define the marketplace behavior.
A public marketplace can be removed even if it has registered apps.
}
type opennebula_market_mad_conf = {
    @{name of the market driver}
    "name" : string = "one"
    @{comma separated list of required attributes in the Market template}
    "required_attrs" : string[] = list('')
    @{list of actions allowed for a MarketPlaceApp.
        monitor: the apps of the marketplace will be monitored.
        create: the app in the marketplace.
        delete: the app from the marketplace.
    }
    "app_actions" : string[] = list('monitor')
    @{set to TRUE for external marketplaces}
    "public" ? boolean
} = dict();

@documentation{ 
The following attributes define the default cost for Virtual Machines that don't have 
a CPU, MEMORY or DISK cost.
This is used by the oneshowback calculate method.
}
type opennebula_default_cost = {
    "cpu_cost" : long = 0
    "memory_cost" : long = 0
    "disk_cost" : long = 0
} = dict();

@documentation{
VNC_BASE_PORT is deprecated since OpenNebula 5.0
OpenNebula will automatically assign start + vmid,
allowing to generate different ports for VMs so they do not collide.
}
type opennebula_vnc_ports = {
    @{VNC port pool for automatic VNC port assignment,
    if possible the port will be set to START + VMID}
    "start" : long = 5900
    "reserved" ? long
} = dict() with {deprecated(0, "VNC_BASE_PORT is deprecated since OpenNebula 5.0"); true;};

@documentation{
LAN ID pool for the automatic VLAN_ID assignment.
This pool is for 802.1Q networks (Open vSwitch and 802.1Q drivers).
The driver will try first to allocate VLAN_IDS[START] + VNET_ID
}
type opennebula_vlan_ids = {
    @{first VLAN_ID to use}
    "start" : long = 2
    "reserved" ? long
} = dict();

@documentation{
Automatic VXLAN Network ID (VNI) assignment. 
This is used or vxlan networks.
NOTE: reserved is not supported by this pool
}
type opennebula_vxlan_ids = {
    @{first VNI (Virtual Network ID) to use}
    "start" : long = 2
} = dict();

@documentation{
Drivers to manage different marketplaces, specialized for the storage backend.
}
type opennebula_market_mad = {
    @{path of the transfer driver executable, can be an absolute path or
    relative to $ONE_LOCATION/lib/mads (or /usr/lib/one/mads/ if OpenNebula was 
    installed in /)
    }
    "executable" : string = 'one_market'
    @{arguments for the driver executable:
        -t number of threads, i.e. number of repo operations at the same time
        -m marketplace mads separated by commas
    }
    "arguments" : string = '-t 15 -m http,s3,one'
} = dict();

@documentation{ 
check if a specific type of datastore has the right attributes
}
function is_consistent_datastore = {
    ds = ARGV[0];
    if (ds['ds_mad'] == 'ceph') {
        if (ds['tm_mad'] != 'ceph') {
            error("for a ceph datastore both ds_mad and tm_mad should have value 'ceph'");
            return(false);
        };
        req = list('bridge_list', 'ceph_host', 'ceph_secret', 'ceph_user', 'ceph_user_key', 'pool_name');
        foreach(idx; attr; req) {
            if(!exists(ds[attr])) {
                error(format("Invalid ceph datastore! Expected '%s' ", attr));
                return(false);
            };
        };
    };
    if (ds['ds_mad'] == 'fs') {
        if (ds['tm_mad'] != 'shared') {
            error("for a fs datastore only 'shared' tm_mad is supported for the moment");
            return(false);
        };
    };
    # Checks for other types can be added here
    return(true);
};

@documentation{ 
type for ceph datastore specific attributes. 
ceph_host, ceph_secret, ceph_user, ceph_user_key and pool_name are mandatory
}
type opennebula_ceph_datastore = {
    "ceph_host"                 ? string[]
    "ceph_secret"               ? type_uuid
    "ceph_user"                 ? string
    "ceph_user_key"             ? string
    "pool_name"                 ? string
    "rbd_format"                ? long(1..2)
};

@documentation{ 
type for vnet ars specific attributes. 
type and size are mandatory 
}
type opennebula_ar = {
    "type"                      : string with match(SELF, "^(IP4|IP6|IP4_6|ETHER)$")
    "ip"                        ? type_ipv4
    "size"                      : long (1..)
    "mac"                       ? type_hwaddr
    "global_prefix"             ? string
    "ula_prefix"                ? string
};

@documentation{ 
type for an opennebula datastore. Defaults to a ceph datastore (ds_mad is ceph).
shared DS is also supported
}
type opennebula_datastore = {
    include opennebula_ceph_datastore
    "name"                      : string
    "bridge_list"               ? string[]  # mandatory for ceph ds, lvm ds, ..
    "datastore_capacity_check"  : boolean = true
    "disk_type"                 : string = 'RBD'
    "ds_mad"                    : string = 'ceph' with match (SELF, '^(fs|ceph)$')
    "tm_mad"                    : string = 'ceph' with match (SELF, '^(shared|ceph)$')
    "type"                      : string = 'IMAGE_DS'
} with is_consistent_datastore(SELF);

type opennebula_vnet = {
    "name" : string
    "bridge" : string
    "gateway" : type_ipv4
    "dns" : type_ipv4
    "network_mask" : type_ipv4
    "bridge_ovs" ? string
    "vlan" ? boolean
    "vlan_id" ? long(0..4095)
    "ar" ? opennebula_ar
};

type opennebula_user = {
    "ssh_public_key" ? string[]
    "user" : string 
    "password" ? string
};

type opennebula_remoteconf_ceph = {
    "pool_name" : string
    "host" : string
    "ceph_user" ? string
    "staging_dir" ? directory = '/var/tmp'
    "rbd_format" ? long(1..2)
    "qemu_img_convert_args" ? string
};

@documentation{
Type that sets the OpenNebula
oned.conf file
}
type opennebula_oned = {
    "db" : opennebula_db
    "default_device_prefix" ? string = 'hd' with match (SELF, '^(hd|sd|vd)$')
    "onegate_endpoint" ? string
    "manager_timer" ? long
    "monitoring_interval" : long = 60
    "monitoring_threads" : long = 50
    "host_per_interval" ? long
    "host_monitoring_expiration_time" ? long
    "vm_individual_monitoring" ? boolean
    "vm_per_interval" ? long
    "vm_monitoring_expiration_time" ? long
    "vm_submit_on_hold" ? boolean
    "max_conn" ? long
    "max_conn_backlog" ? long
    "keepalive_timeout" ? long
    "keepalive_max_conn" ? long
    "timeout" ? long
    "rpc_log" ? boolean
    "message_size" ? long
    "log_call_format" ? string
    "scripts_remote_dir" : directory = '/var/tmp/one'
    "log" : opennebula_log
    "federation" : opennebula_federation
    "port" : long = 2633
    "vnc_base_port" : long = 5900
    "network_size" : long = 254
    "mac_prefix" : string = '02:00'
    "datastore_location" ? directory = '/var/lib/one/datastores'
    "datastore_base_path" ? directory = '/var/lib/one/datastores'
    "datastore_capacity_check" : boolean = true
    "default_image_type" : string = 'OS' with match (SELF, '^(OS|CDROM|DATABLOCK)$')
    "default_cdrom_device_prefix" : string = 'hd' with match (SELF, '^(hd|sd|vd)$')
    "session_expiration_time" : long = 900
    "default_umask" : long = 177
    "im_mad" : opennebula_im_mad
    "vm_mad" : opennebula_vm_mad
    "tm_mad" : opennebula_tm_mad
    "datastore_mad" : opennebula_datastore_mad
    "hm_mad" : opennebula_hm_mad
    "auth_mad" : opennebula_auth_mad
    "market_mad" : opennebula_market_mad
    "default_cost" : opennebula_default_cost
    "listen_address" : type_ipv4 = '0.0.0.0'
    "vnc_ports" : opennebula_vnc_ports
    "vlan_ids" : opennebula_vlan_ids
    "vxlan_ids" : opennebula_vxlan_ids
    "tm_mad_conf" : opennebula_tm_mad_conf[] = list(
        dict("ds_migrate", true), 
        dict("name", "lvm", "clone_target", "SELF"), 
        dict("name", "shared", "ds_migrate", true), 
        dict("name", "fs_lvm", "ln_target", "SYSTEM"), 
        dict("name", "qcow2"), 
        dict("name", "ssh", "ln_target", "SYSTEM", "shared", false, "ds_migrate", true), 
        dict("name", "vmfs"), 
        dict("name", "ceph", "clone_target", "SELF", "ds_migrate", false),
        dict("name", "iscsi_libvirt", "clone_target", "SELF", "ds_migrate", false),
        dict("name", "dev", "clone_target", "NONE"),
        dict("name", "vcenter", "clone_target", "NONE"),
    )
    "ds_mad_conf" : opennebula_ds_mad_conf[] = list(
        dict(),
        dict("name", "ceph", "required_attrs", list('DISK_TYPE', 'BRIDGE_LIST', 'CEPH_HOST', 'CEPH_USER', 'CEPH_SECRET'),
             "marketplace_actions", "export"),
        dict("name", "dev", "required_attrs", list('DISK_TYPE'),
             "persistent_only", true),
        dict("name", "iscsi_libvirt", "required_attrs", list('DISK_TYPE', 'ISCSI_HOST'),
             "persistent_only", true),
        dict("name", "fs", "marketplace_actions", "export"),
        dict("name", "lvm", "required_attrs", list('DISK_TYPE', 'BRIDGE_LIST')),
        dict("name", "vcenter", "required_attrs", list('VCENTER_CLUSTER'), "persistent_only", true,
             "marketplace_actions", "export"),
    )
    "market_mad_conf" : opennebula_market_mad_conf[] = list(
        dict("public", true),
        dict("name", "http", "required_attrs", list('BASE_URL', 'PUBLIC_DIR'), "app_actions", list('create', 'delete', 'monitor')),
        dict("name", "s3", "required_attrs", list('ACCESS_KEY_ID', 'SECRET_ACCESS_KEY', 'REGION', 'BUCKET'),
             "app_actions", list('create', 'delete', 'monitor')),
    )
    "vm_restricted_attr" : string[] = list("CONTEXT/FILES", "NIC/MAC", "NIC/VLAN_ID", "NIC/BRIDGE", 
                                           "NIC_DEFAULT/MAC", "NIC_DEFAULT/VLAN_ID", "NIC_DEFAULT/BRIDGE", 
                                           "DISK/TOTAL_BYTES_SEC", "DISK/READ_BYTES_SEC", "DISK/WRITE_BYTES_SEC", 
                                           "DISK/TOTAL_IOPS_SEC", "DISK/READ_IOPS_SEC", "DISK/WRITE_IOPS_SEC", 
                                           "DISK/ORIGINAL_SIZE", "CPU_COST", "MEMORY_COST", "DISK_COST", 
                                           "PCI", "USER_INPUTS")
    "image_restricted_attr" : string = 'SOURCE'
    "vnet_restricted_attr" : string[] = list("VN_MAD", "PHYDEV", "VLAN_ID", "BRIDGE", "AR/VN_MAD", 
                                             "AR/PHYDEV", "AR/VLAN_ID", "AR/BRIDGE")
    "inherit_datastore_attr" : string[] = list("CEPH_HOST", "CEPH_SECRET", "CEPH_USER", "CEPH_CONF", 
                                               "RBD_FORMAT", "POOL_NAME", "ISCSI_USER", "ISCSI_USAGE", 
                                               "ISCSI_HOST", "GLUSTER_HOST", "GLUSTER_VOLUME", 
                                               "DISK_TYPE", "ADAPTER_TYPE")
    "inherit_image_attr" : string[] = list("ISCSI_USER", "ISCSI_USAGE", "ISCSI_HOST", "ISCSI_IQN", 
                                           "DISK_TYPE", "ADAPTER_TYPE")
    "inherit_vnet_attr" : string[] = list("VLAN_TAGGED_ID", "BRIDGE_OVS", "FILTER_IP_SPOOFING", 
                                          "FILTER_MAC_SPOOFING", "MTU")
};


type opennebula_instance_types = {
    "name" : string
    "cpu" : long(1..)
    "vcpu" : long(1..)
    "memory" : long
    "description" ? string
} = dict();


@documentation{
Type that sets the OpenNebula
sunstone_server.conf file
}
type opennebula_sunstone = {
    "tmpdir" : directory = '/var/tmp'
    "one_xmlrpc" : type_absoluteURI = 'http://localhost:2633/RPC2'
    "host" : type_ipv4 = '127.0.0.1'
    "port" : long = 9869
    "sessions" : string = 'memory' with match (SELF, '^(memory|memcache)$')
    "memcache_host" : string = 'localhost'
    "memcache_port" : long = 11211
    "memcache_namespace" : string = 'opennebula.sunstone'
    "debug_level" : long (0..3) = 3
    "auth" : string = 'opennebula' with match (SELF, '^(sunstone|opennebula|x509|remote)$')
    "core_auth" : string = 'cipher' with match (SELF, '^(cipher|x509)$')
    "encode_user_password" ? boolean
    "vnc_proxy_port" : long = 29876
    "vnc_proxy_support_wss" : string = 'no' with match (SELF, '^(no|yes|only)$')
    "vnc_proxy_cert" : string = ''
    "vnc_proxy_key" : string = ''
    "vnc_proxy_ipv6" : boolean = false
    "lang" : string = 'en_US'
    "table_order" : string = 'desc' with match (SELF, '^(desc|asc)$')
    "marketplace_username" ? string
    "marketplace_password" ? string
    "marketplace_url" : type_absoluteURI = 'http://marketplace.opennebula.systems/appliance'
    "oneflow_server" : type_absoluteURI = 'http://localhost:2474/'
    "instance_types" : opennebula_instance_types[] = list (
        dict("name", "small-x1", "cpu", 1, "vcpu", 1, "memory", 128, "description", "Very small instance for testing purposes"),
        dict("name", "small-x2", "cpu", 2, "vcpu", 2, "memory", 512, "description", "Small instance for testing multi-core applications"),
        dict("name", "medium-x2", "cpu", 2, "vcpu", 2, "memory", 1024, "description", "General purpose instance for low-load servers"),
        dict("name", "medium-x4", "cpu", 4, "vcpu", 4, "memory", 2048, "description", "General purpose instance for medium-load servers"),
        dict("name", "large-x4", "cpu", 4, "vcpu", 4, "memory", 4096, "description", "General purpose instance for servers"),
        dict("name", "large-x8", "cpu", 8, "vcpu", 8, "memory", 8192, "description", "General purpose instance for high-load servers"),
    )
    "routes" : string[] = list("oneflow", "vcenter", "support")
};

@documentation{
Type that sets the OpenNebula
VMM kvmrc conf files
}
type opennebula_kvmrc = {
    "lang" : string = 'C'
    "libvirt_uri" : string = 'qemu:///system'
    "qemu_protocol" : string = 'qemu+ssh' with match (SELF, '^(qemu\+ssh|qemu\+tcp)$')
    "libvirt_keytab" ? string
    "shutdown_timeout" : long = 300
    "force_destroy" ? boolean
    "cancel_no_acpi" ? boolean
    "default_attach_cache" ? string with match (SELF, '^(default|none|writethrough|writeback|directsync|unsafe)$')
    "migrate_options" ? string
    "default_attach_discard" ? string with match (SELF, '^(ignore|off|unmap|on)$')
};

@documentation{ 
Type that sets the OpenNebula conf
to contact to ONE RPC server
}
type opennebula_rpc = {
    "port" : long(0..) = 2633
    "host" : string = 'localhost'
    "user" : string = 'oneadmin'
    "password" : string
} = dict();

@documentation{
Type that sets the OpenNebula
untouchable resources
}
type opennebula_untouchables = {
    "datastores" ? string[]
    "vnets" ? string[]
    "users" ? string[]
    "hosts" ? string[]
};


@documentation{
Type to define ONE basic resources
datastores, vnets, hosts names, etc
}
type component_opennebula = {
    include structure_component
    'datastores'    ? opennebula_datastore[1..]
    'users'         ? opennebula_user[]
    'vnets'         ? opennebula_vnet[]
    'hosts'         ? string[]
    'rpc'           ? opennebula_rpc
    'untouchables'  ? opennebula_untouchables
    'oned'          ? opennebula_oned
    'sunstone'      ? opennebula_sunstone
    'kvmrc'         ? opennebula_kvmrc
    'ssh_multiplex' : boolean = true
    'cfg_group'     ? string
    'host_ovs'      ? boolean
    'host_hyp'      : string = 'kvm' with match (SELF, '^(kvm|xen)$')
    'tm_system_ds'  ? string with match(SELF, "^(shared|ssh|vmfs)$")
    'v5_config'     ? boolean
} = dict();

