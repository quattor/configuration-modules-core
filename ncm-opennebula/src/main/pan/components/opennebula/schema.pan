# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/opennebula/schema;

include 'quattor/schema';
include 'pan/types';
include 'quattor/aii/opennebula/schema';

include 'components/opennebula/common';
include 'components/opennebula/monitord';
include 'components/opennebula/sched';

type opennebula_federation = {
    "mode" : string = 'STANDALONE' with match (SELF, '^(STANDALONE|MASTER|SLAVE)$')
    "zone_id" : long = 0
    "master_oned" : string = ''
    "server_id" : long(-1..) = -1
} = dict();

@documentation{
Since 5.12.x Opennebula uses the Raft algorithm.
It can be tuned by several parameters in the configuration file
}
type opennebula_raft = {
    @{Number of DB log records that will be deleted on each purge}
    "limit_purge" : long(1..) = 100000
    @{Number of DB log records kept. It determines the synchronization
    window across servers and extra storage space needed}
    "log_retention" : long(1..) = 250000
    @{How often applied records are purged according to the log
    retention value (in seconds)}
    "log_purge_timeout" : long(1..) = 60
    @{Timeout to start an election process if no heartbeat or log
    is received from the leader (in milliseconds)}
    "election_timeout_ms" : long(1..) = 5000
    @{How often heartbeats are sent to followers (in milliseconds)}
    "broadcast_timeout_ms" : long(1..) = 500
    @{Timeout for Raft-related API calls (in milliseconds).
    For an infinite timeout, set this value to 0}
    "xmlrpc_timeout_ms" : long(0..) = 1000
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
    "arguments" : string  = '-t 15 -d dummy,fs,lvm,ceph,dev,iscsi_libvirt,vcenter -s shared,ssh,ceph,fs_lvm,qcow2,vcenter'
} = dict();

type opennebula_hm_mad = {
    "executable" : string = 'one_hm'
    @{for the driver executable, can be an absolute path or relative
    to $ONE_LOCATION/etc (or /etc/one/ if OpenNebula was installed in /)}
    "arguments" : string = '-p 2101 -l 2102 -b 127.0.0.1'
} = dict();

type opennebula_hook_log_conf = {
    @{Number of execution records saved in the database for each hook}
    "log_retention" : long(1..) = 20
} = dict();

type opennebula_auth_mad = {
    "executable" : string = 'one_auth_mad'
    "authn" : string = 'ssh,x509,ldap,server_cipher,server_x509'
} = dict();

type opennebula_tm_mad_conf = {
    "name" : string = "dummy"
    "ln_target" : string = "NONE"
    "clone_target" : choice('SYSTEM', 'NONE', 'SELF') = "SYSTEM"
    "shared" : boolean = true
    "ds_migrate" ? boolean
    "driver" ? choice('raw', 'qcow2')
    "allow_orphans" ? string
    "tm_mad_system" ? string
    "ln_target_ssh" ? string
    "clone_target_ssh" ? string
    "disk_type_ssh" ? string
    "ln_target_shared" ? string
    "clone_target_shared" ? string
    "disk_type_shared" ? string
} = dict();

@documentation{
Authentication Driver Behavior Definition.
The configuration for each driver is defined in AUTH_MAD_CONF.
}
type opennebula_auth_mad_conf = {
    @{Name of the auth driver}
    "name" : string
    @{Allow the end users to change their own password.
    Oneadmin can still change other users passwords}
    "password_change" : boolean
    @{Allow the driver to set the users group even after
    user creation. In this case addgroup, delgroup and chgrp
    will be disabled, with the exception of chgrp to one of
    the groups in the list of secondary groups}
    "driver_managed_groups" : boolean = false
    @{Limit the maximum token validity, in seconds. Use -1 for
    unlimited maximum, 0 to disable login tokens}
    "max_token_time" : long(-1..) = -1
} = dict();

@documentation{
Virtual Network Driver Behavior Definition.
The configuration for each driver is defined in VN_MAD_CONF.
}
type opennebula_vn_mad_conf = {
    @{Name of the auth driver}
    "name" : string
    @{Define the technology used by the driver}
    "bridge_type" : choice('linux', 'openvswitch', 'vcenter_port_groups') = 'linux'
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
    @{Name displayed in Sunstone}
    "sunstone_name" : string = "OpenNebula.org Marketplace"
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
    "start" : long(5900..65535) = 5900
    @{Comma-separated list of reserved ports or ranges. Two numbers separated by a colon indicate a range}
    "reserved" ? string = "32768:65536"
} = dict() with {deprecated(0, "VNC_BASE_PORT is deprecated since OpenNebula 5.0"); true; };

@documentation{
LAN ID pool for the automatic VLAN_ID assignment.
This pool is for 802.1Q networks (Open vSwitch and 802.1Q drivers).
The driver will try first to allocate VLAN_IDS[START] + VNET_ID
}
type opennebula_vlan_ids = {
    @{first VLAN_ID to use}
    "start" : long = 2
    @{Comma-separated list of VLAN_IDs or ranges.
    Two numbers separated by a colon indicate a range}
    "reserved" ? string = "0, 1, 4095"
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
    "arguments" : string = '-t 15 -m http,s3,one,linuxcontainers,turnkeylinux,dockerhub'
} = dict();

@documentation{
type for ceph datastore specific attributes.
ceph_host, ceph_secret, ceph_user, ceph_user_key and pool_name are mandatory
}
type opennebula_ceph_datastore = {
    "ceph_host" ? string[]
    "ceph_secret" ? type_uuid
    "ceph_user" ? string
    "ceph_user_key" ? string
    "pool_name" ? string
    "rbd_format" ? long(1..2)
};

@documentation{
type for vnet ars specific attributes.
type and size are mandatory
}
type opennebula_ar = {
    "type" : string with match(SELF, "^(IP4|IP6|IP4_6|ETHER)$")
    "ip" ? type_ipv4
    "size" : long (1..)
    "mac" ? type_hwaddr
    "global_prefix" ? string
    "ula_prefix" ? string
};

@documentation{
type for an opennebula datastore. Defaults to a ceph datastore (ds_mad is ceph).
shared DS is also supported
}
type opennebula_datastore = {
    include opennebula_ceph_datastore
    "bridge_list" ? string[]  # mandatory for ceph ds, lvm ds, ..
    "datastore_capacity_check" : boolean = true
    "disk_type" ? choice('RBD', 'BLOCK', 'CDROM', 'FILE')
    "ds_mad" ? choice('fs', 'ceph', 'dev')
    @{set system Datastore TM_MAD value.
        shared: The storage area for the system datastore is a shared directory across the hosts.
        vmfs: A specialized version of the shared one to use the vmfs file system.
        ssh: Uses a local storage area from each host for the system datastore.
        ceph: Uses Ceph storage backend.
    }
    "tm_mad" : choice('shared', 'ceph', 'ssh', 'vmfs', 'dev') = 'ceph'
    "type" : choice('IMAGE_DS', 'SYSTEM_DS') = 'IMAGE_DS'
    @{datastore labels is a list of strings to group the datastores under a given name and filter them
    in the admin and cloud views. It is also possible to include in the list
    sub-labels using a common slash: list("Name", "Name/SubName")}
    "labels" ? string[]
    "permissions" ? opennebula_permissions
    @{Adds the datastore to the given clusters}
    "clusters" ? string[]
} = dict() with is_consistent_datastore(SELF);

type opennebula_vnet = {
    "bridge" ? string
    "vn_mad" : string = 'dummy' with match (SELF, '^(802.1Q|ebtables fw|ovswitch|vxlan|vcenter|dummy)$')
    "gateway" ? type_ipv4
    "gateway6" ? type_network_name
    "dns" ? type_ipv4
    "network_mask" ? type_ipv4
    "network_address" ? type_ipv4
    "guest_mtu" ? long
    "context_force_ipv4" ? boolean
    "search_domain" ? string
    "bridge_ovs" ? string
    "vlan" ? boolean
    "vlan_id" ? long(0..4095)
    "ar" ? opennebula_ar
    @{vnet labels is a list of strings to group the vnets under a given name and filter them
    in the admin and cloud views. It is also possible to include in the list
    sub-labels using a common slash: list("Name", "Name/SubName")}
    "labels" ? string[]
    @{set network filter to avoid IP spoofing for the current vnet}
    "filter_ip_spoofing" ? boolean
    @{set network filter to avoid MAC spoofing for the current vnet}
    "filter_mac_spoofing" ? boolean
    @{Name of the physical network device that will be attached to the bridge (VXLAN)}
    "phydev" ? string
    @{MTU for the tagged interface and bridge (VXLAN)}
    "mtu" ? long(1500..)
    "permissions" ? opennebula_permissions
    @{Adds the vnet to the given clusters}
    "clusters" ? string[]
} = dict() with is_consistent_vnet(SELF);

@documentation{
Set OpenNebula hypervisor options and their virtual clusters (if any)
}
type opennebula_host = {
    @{set OpenNebula hosts type.}
    'host_hyp' : string = 'kvm' with match (SELF, '^(kvm|xen)$')
    @{Set the hypervisor cluster. Any new hypervisor is always included within
    "Default" cluster.
    Hosts can be in only one cluster at a time.}
    "cluster" ? string
    @{Define which Hosts are going to be used to run pinned workloads setting PIN_POLICY.
    A Host can operate in two modes:

    NONE: Default mode where no NUMA or hardware characteristics are considered.
    Resources are assigned and balanced by an external component, e.g. numad or kernel.

    PINNED: VMs are allocated and pinned to specific nodes according to different policies.

    See:
    https://docs.opennebula.io/6.6/management_and_operations/host_cluster_management/numa.html#configuring-the-host}
    "pin_policy" ? choice('NONE', 'PINNED')
};

@documentation{
Set OpenNebula regular users and their primary groups.
By default new users are assigned to the users group.
}
type opennebula_user = {
    "ssh_public_key" ? string[]
    "password" ? string
    "group" ? string
    @{user labels is a list of strings to group the users under a given name and filter them
    in the admin and cloud views. It is also possible to include in the list
    sub-labels using a common slash: list("Name", "Name/SubName")}
    "labels" ? string[]
} = dict();

@documentation{
Set a group name and an optional decription
}
type opennebula_group = {
    "description" ? string
    "labels" ? string[]
} = dict();

@documentation{
Set OpenNebula clusters and their porperties.
}
type opennebula_cluster = {
    include opennebula_group
    @{In percentage. Applies to all the Hosts in this cluster.
    It will be subtracted from the TOTAL CPU.
    This value can be negative, in that case you’ll be actually
    increasing the overall capacity so overcommiting host capacity.}
    "reserved_cpu" ? long
    @{In KB. Applies to all the Hosts in this cluster.
    It will be subtracted from the TOTAL MEM.
    This value can be negative, in that case you’ll be actually
    increasing the overall capacity so overcommiting host capacity.}
    "reserved_mem" ? long
} = dict();

@documentation{
type for vmgroup roles specific attributes.
}
type opennebula_vmgroup_role = {
    @{The name of the role, it needs to be unique within the VM Group}
    "name" : string
    @{Placement policy for the VMs of the role}
    "policy" ? choice('AFFINED', 'ANTI_AFFINED')
    @{Defines a set of hosts (by their ID) where the VMs of the role can be executed}
    "host_affined" ? string[]
    @{Defines a set of hosts (by their ID) where the VMs of the role cannot be executed}
    "host_anti_affined" ? string[]
};


@documentation{
Set OpenNebula vmgroups and their porperties.
}
type opennebula_vmgroup = {
    include opennebula_group
    "role" ? opennebula_vmgroup_role[]
    @{List of roles whose VMs has to be placed in the same host}
    "affined" ? string[]
    @{List of roles whose VMs cannot be placed in the same host}
    "anti_affined" ? string[]
} = dict();


type opennebula_remoteconf_ceph = {
    "pool_name" : string
    "host" : string
    "ceph_user" ? string
    "staging_dir" ? absolute_file_path = '/var/tmp'
    "rbd_format" ? long(1..2)
    "qemu_img_convert_args" ? string
};

@documentation{
Type that sets the OpenNebula
oned.conf file
}
type opennebula_oned = {
    "db" : opennebula_db
    "default_device_prefix" ? opennebula_device_prefix = 'hd'
    "onegate_endpoint" ? string
    "manager_timer" ? long
    "monitoring_interval" : long = 60
    "monitoring_threads" : long = 50
    @{Time in seconds between each DATASTORE monitoring cycle}
    "monitoring_interval_datastore" : long(0..) = 300
    @{Time in seconds between each MARKETPLACE monitoring cycle}
    "monitoring_interval_market" : long(0..) = 600
    @{Time in seconds between DB writes of VM monitoring information.
    -1 to disable DB updating and 0 to write every update}
    "monitoring_interval_db_update" : long(-1..) = 0
    "host_per_interval" ? long
    "host_monitoring_expiration_time" ? long
    "vm_individual_monitoring" ? boolean
    "vm_per_interval" ? long
    "vm_monitoring_expiration_time" ? long
    "vm_submit_on_hold" ? boolean
    "vm_admin_operations" : string[] = list(
        'migrate',
        'delete',
        'recover',
        'retry',
        'deploy',
        'resched',
    )
    @{The following parameters define the operations associated to the ADMIN,
    MANAGE and USE permissions. Note that some VM operations require additional
    permissions on other objects. Also some operations refers to a class of
    actions:
        - disk-snapshot, includes create, delete and revert actions
        - disk-attach, includes attach and detach actions
        - nic-attach, includes attach and detach actions
        - snapshot, includes create, delete and revert actions
        - resched, includes resched and unresched actions
    }
    "vm_manage_operations" : string[] = list(
        'undeploy',
        'hold',
        'release',
        'stop',
        'suspend',
        'resume',
        'reboot',
        'poweroff',
        'disk-attach',
        'nic-attach',
        'disk-snapshot',
        'terminate',
        'disk-resize',
        'snapshot',
        'updateconf',
        'rename',
        'resize',
        'update',
        'disk-saveas',
    )
    "vm_use_operations" : string[] = list('')
    @{Default ACL rules created when a resource is added to a VDC.
    The following attributes configure the permissions granted to the VDC group for each resource type}
    "default_vdc_host_acl" : opennebula_vdc_rules = 'MANAGE'
    "default_vdc_vnet_acl" : opennebula_vdc_rules = 'USE'
    "default_vdc_datastore_acl" : opennebula_vdc_rules = 'USE'
    "default_vdc_cluster_host_acl" : opennebula_vdc_rules = 'MANAGE'
    "default_vdc_cluster_net_acl" : opennebula_vdc_rules = 'USE'
    "default_vdc_cluster_datastore_acl" : opennebula_vdc_rules = 'USE'
    "max_conn" ? long
    "max_conn_backlog" ? long
    "keepalive_timeout" ? long
    "keepalive_max_conn" ? long
    "timeout" ? long
    "rpc_log" ? boolean
    "message_size" ? long
    "log_call_format" ? string
    "scripts_remote_dir" : absolute_file_path = '/var/tmp/one'
    "log" : opennebula_log
    "federation" : opennebula_federation
    "raft" : opennebula_raft
    "port" : type_port = 2633
    "vnc_base_port" : long = 5900
    "network_size" : long = 254
    "mac_prefix" : string = '02:00'
    "datastore_location" ? absolute_file_path = '/var/lib/one/datastores'
    "datastore_base_path" ? absolute_file_path = '/var/lib/one/datastores'
    "datastore_capacity_check" : boolean = true
    "default_image_type" : string = 'OS' with match (SELF, '^(OS|CDROM|DATABLOCK)$')
    "default_cdrom_device_prefix" : opennebula_device_prefix = 'hd'
    "session_expiration_time" : long = 900
    "default_umask" : long = 177
    "im_mad" : opennebula_im[] = list(
        dict(
            "name", "kvm",
            "arguments", "-r 3 -t 15 kvm",
            "executable", "one_im_ssh",
            "sunstone_name", "KVM",
        ),
        # monitord replaces collectd since 5.12 release
        dict(
            "name", "monitord",
            "arguments", "-c monitord.conf",
            "executable", "onemonitord",
            "threads", 8,
        ),
    )
    "vm_mad" : opennebula_vm_mad
    "tm_mad" : opennebula_tm_mad
    "datastore_mad" : opennebula_datastore_mad
    "hm_mad" : opennebula_hm_mad
    "hook_log_conf" : opennebula_hook_log_conf
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
        dict(
            "name", "shared",
            "ds_migrate", true,
            "tm_mad_system", "ssh",
            "ln_target_ssh", "SYSTEM",
            "clone_target_ssh", "SYSTEM",
            "disk_type_ssh", "FILE",
        ),
        dict(
            "name", "fs_lvm",
            "ln_target", "SYSTEM",
            "driver", "raw",
        ),
        dict(
            "name", "qcow2",
            "driver", "qcow2",
            "ds_migrate", true,
            "tm_mad_system", "ssh",
            "ln_target_ssh", "SYSTEM",
            "clone_target_ssh", "SYSTEM",
            "disk_type_ssh", "FILE",
        ),
        dict("name", "ssh", "ln_target", "SYSTEM", "shared", false, "ds_migrate", true),
        dict("name", "vmfs"),
        dict(
            "name", "ceph",
            "clone_target", "SELF",
            "ds_migrate", false,
            "driver", "raw",
            "allow_orphans", "mixed",
            "tm_mad_system", "ssh,shared",
            "ln_target_ssh", "SYSTEM",
            "clone_target_ssh", "SYSTEM",
            "disk_type_ssh", "FILE",
            "ln_target_shared", "NONE",
            "clone_target_shared", "SELF",
            "disk_type_shared", "rbd",
        ),
        dict("name", "iscsi_libvirt", "clone_target", "SELF", "ds_migrate", false),
        dict(
            "name", "dev",
            "clone_target", "NONE",
            "tm_mad_system", "ssh,shared",
            "ln_target_ssh", "SYSTEM",
            "clone_target_ssh", "SYSTEM",
            "disk_type_ssh", "FILE",
            "ln_target_shared", "NONE",
            "clone_target_shared", "SELF",
            "disk_type_shared", "FILE",
        ),
        dict("name", "vcenter", "clone_target", "NONE"),
    )
    "ds_mad_conf" : opennebula_ds_mad_conf[] = list(
        dict(),
        dict(
            "name", "ceph",
            "required_attrs", list('DISK_TYPE', 'BRIDGE_LIST', 'CEPH_HOST', 'CEPH_USER', 'CEPH_SECRET'),
            "marketplace_actions", "export",
        ),
        dict(
            "name", "dev",
            "required_attrs", list('DISK_TYPE'),
            "persistent_only", true,
        ),
        dict(
            "name", "iscsi_libvirt",
            "required_attrs", list('DISK_TYPE', 'ISCSI_HOST'),
            "persistent_only", true,
        ),
        dict(
            "name", "fs",
            "marketplace_actions", "export",
        ),
        dict(
            "name", "lvm",
            "required_attrs", list('DISK_TYPE', 'BRIDGE_LIST'),
        ),
        dict(
            "name", "vcenter",
            "required_attrs", list('VCENTER_INSTANCE_ID', 'VCENTER_DS_REF', 'VCENTER_DC_REF'),
            "persistent_only", false,
            "marketplace_actions", "export",
        ),
    )
    "market_mad_conf" : opennebula_market_mad_conf[] = list(
        dict(
            "public", true,
        ),
        dict(
            "sunstone_name", "HTTP server",
            "name", "http",
            "required_attrs", list('BASE_URL', 'PUBLIC_DIR'),
            "app_actions", list('create', 'delete', 'monitor'),
        ),
        dict(
            "sunstone_name", "Amazon S3",
            "name", "s3",
            "required_attrs", list('ACCESS_KEY_ID', 'SECRET_ACCESS_KEY', 'REGION', 'BUCKET'),
            "app_actions", list('create', 'delete', 'monitor'),
        ),
        dict(
            "sunstone_name", "LinuxContainers.org",
            "name", "linuxcontainers",
            "app_actions", list('monitor'),
            "public", true,
        ),
        dict(
            "sunstone_name", "TurnkeyLinux",
            "name", "turnkeylinux",
            "app_actions", list('monitor'),
            "public", true,
        ),
        dict(
            "sunstone_name", "DockerHub",
            "name", "dockerhub",
            "app_actions", list('monitor'),
            "public", true,
        ),
    )
    "auth_mad_conf" : opennebula_auth_mad_conf[] = list(
        dict(
            "name", "core",
            "password_change", true,
        ),
        dict(
            "name", "public",
            "password_change", false,
        ),
        dict(
            "name", "ssh",
            "password_change", true,
        ),
        dict(
            "name", "x509",
            "password_change", false,
        ),
        dict(
            "name", "ldap",
            "password_change", true,
            "driver_managed_groups", true,
            "max_token_time", 86400,
        ),
        dict(
            "name", "server_cipher",
            "password_change", false,
        ),
        dict(
            "name", "server_x509",
            "password_change", false,
        ),
    )
    "vn_mad_conf" : opennebula_vn_mad_conf[] = list(
        dict("name", "dummy"),
        dict("name", "802.1Q"),
        dict("name", "ebtables"),
        dict("name", "fw"),
        dict("name", "ovswitch", "bridge_type", "openvswitch"),
        dict("name", "vxlan"),
        dict("name", "vcenter", "bridge_type", "vcenter_port_groups"),
        dict("name", "ovswitch_vxlan", "bridge_type", "openvswitch"),
        dict("name", "bridge"),
    )
    "vm_restricted_attr" : string[] = list(
        "CONTEXT/FILES",
        "NIC/MAC",
        "NIC/VLAN_ID",
        "NIC/BRIDGE",
        "NIC/FILTER",
        "NIC/INBOUND_AVG_BW",
        "NIC/INBOUND_PEAK_BW",
        "NIC/INBOUND_PEAK_KB",
        "NIC/OUTBOUND_AVG_BW",
        "NIC/OUTBOUND_PEAK_BW",
        "NIC/OUTBOUND_PEAK_KB",
        "NIC/OPENNEBULA_MANAGED",
        "NIC/VCENTER_INSTANCE_ID",
        "NIC/VCENTER_NET_REF",
        "NIC/VCENTER_PORTGROUP_TYPE",
        "NIC/EXTERNAL",
        "NIC_ALIAS/MAC",
        "NIC_ALIAS/VLAN_ID",
        "NIC_ALIAS/BRIDGE",
        "NIC_ALIAS/INBOUND_AVG_BW",
        "NIC_ALIAS/INBOUND_PEAK_BW",
        "NIC_ALIAS/INBOUND_PEAK_KB",
        "NIC_ALIAS/OUTBOUND_AVG_BW",
        "NIC_ALIAS/OUTBOUND_PEAK_BW",
        "NIC_ALIAS/OUTBOUND_PEAK_KB",
        "NIC_ALIAS/OPENNEBULA_MANAGED",
        "NIC_ALIAS/VCENTER_INSTANCE_ID",
        "NIC_ALIAS/VCENTER_NET_REF",
        "NIC_ALIAS/VCENTER_PORTGROUP_TYPE",
        "NIC_ALIAS/EXTERNAL",
        "NIC_DEFAULT/MAC",
        "NIC_DEFAULT/VLAN_ID",
        "NIC_DEFAULT/BRIDGE",
        "NIC_DEFAULT/FILTER",
        "NIC_DEFAULT/EXTERNAL",
        "DISK/TOTAL_BYTES_SEC",
        "DISK/TOTAL_BYTES_SEC_MAX_LENGTH",
        "DISK/TOTAL_BYTES_SEC_MAX",
        "DISK/READ_BYTES_SEC",
        "DISK/READ_BYTES_SEC_MAX_LENGTH",
        "DISK/READ_BYTES_SEC_MAX",
        "DISK/WRITE_BYTES_SEC",
        "DISK/WRITE_BYTES_SEC_MAX_LENGTH",
        "DISK/WRITE_BYTES_SEC_MAX",
        "DISK/TOTAL_IOPS_SEC",
        "DISK/TOTAL_IOPS_SEC_MAX_LENGTH",
        "DISK/TOTAL_IOPS_SEC_MAX",
        "DISK/READ_IOPS_SEC",
        "DISK/READ_IOPS_SEC_MAX_LENGTH",
        "DISK/READ_IOPS_SEC_MAX",
        "DISK/WRITE_IOPS_SEC",
        "DISK/WRITE_IOPS_SEC_MAX_LENGTH",
        "DISK/WRITE_IOPS_SEC_MAX",
        "DISK/OPENNEBULA_MANAGED",
        "DISK/VCENTER_DS_REF",
        "DISK/VCENTER_INSTANCE_ID",
        "DISK/ORIGINAL_SIZE",
        "DISK/SIZE_PREV",
        "DEPLOY_ID",
        "CPU_COST",
        "MEMORY_COST",
        "DISK_COST",
        "PCI",
        "EMULATOR",
        "RAW/DATA",
        "USER_PRIORITY",
        "USER_INPUTS/CPU",
        "USER_INPUTS/MEMORY",
        "USER_INPUTS/VCPU",
        "VCENTER_VM_FOLDER",
        "VCENTER_ESX_HOST",
        "TOPOLOGY/PIN_POLICY",
        "TOPOLOGY/HUGEPAGE_SIZE",
    )
    "image_restricted_attr" : string[] = list(
        "SOURCE",
        "VCENTER_IMPORTED",
    )
    "vnet_restricted_attr" : string[] = list(
        "VN_MAD",
        "PHYDEV",
        "VLAN_ID",
        "BRIDGE",
        "CONF",
        "BRIDGE_CONF",
        "OVS_BRIDGE_CONF",
        "IP_LINK_CONF",
        "FILTER",
        "FILTER_IP_SPOOFING",
        "FILTER_MAC_SPOOFING",
        "AR/VN_MAD",
        "AR/PHYDEV",
        "AR/VLAN_ID",
        "AR/BRIDGE",
        "AR/FILTER",
        "AR/FILTER_IP_SPOOFING",
        "AR/FILTER_MAC_SPOOFING",
        "CLUSTER_IDS",
        "EXTERNAL",
    )
    "user_restricted_attr" : string[] = list(
        "VM_USE_OPERATIONS",
        "VM_MANAGE_OPERATIONS",
        "VM_ADMIN_OPERATIONS",
    )
    "group_restricted_attr" : string[] = list(
        "VM_USE_OPERATIONS",
        "VM_MANAGE_OPERATIONS",
        "VM_ADMIN_OPERATIONS",
    )
    "host_encrypted_attr" : string[] = list(
        "EC2_ACCESS",
        "EC2_SECRET",
        "AZ_SUB",
        "AZ_CLIENT",
        "AZ_SECRET",
        "AZ_TENANT",
        "VCENTER_PASSWORD",
        "NSX_PASSWORD",
        "ONE_PASSWORD",
        "PROVISION/PACKET_TOKEN",
        "PROVISION/EC2_ACCESS",
        "PROVISION/EC2_SECRET",
    )
    "vm_encrypted_attr" : string[] = list("CONTEXT/PASSWORD")
    "vnet_encrypted_attr" : string[] = list("AR/PACKET_TOKEN")
    "datastore_encrypted_attr" : string[] = list("PROVISION/PACKET_TOKEN")
    "cluster_encrypted_attr" : string[] = list("PROVISION/PACKET_TOKEN")
    "inherit_datastore_attr" : string[] = list(
        "CEPH_HOST",
        "CEPH_SECRET",
        "CEPH_KEY",
        "CEPH_USER",
        "CEPH_CONF",
        "CEPH_TRASH",
        "POOL_NAME",
        "ISCSI_USER",
        "ISCSI_USAGE",
        "ISCSI_HOST",
        "ISCSI_IQN",
        "GLUSTER_HOST",
        "GLUSTER_VOLUME",
        "DISK_TYPE",
        "ALLOW_ORPHANS",
        "VCENTER_ADAPTER_TYPE",
        "VCENTER_DISK_TYPE",
        "VCENTER_DS_REF",
        "VCENTER_DS_IMAGE_DIR",
        "VCENTER_DS_VOLATILE_DIR",
        "VCENTER_INSTANCE_ID",
    )
    "inherit_image_attr" : string[] = list(
        "DISK_TYPE",
        "VCENTER_ADAPTER_TYPE",
        "VCENTER_DISK_TYPE",
    )
    "inherit_vnet_attr" : string[] = list(
        "VLAN_TAGGED_ID",
        "FILTER",
        "FILTER_IP_SPOOFING",
        "FILTER_MAC_SPOOFING",
        "MTU",
        "METRIC",
        "INBOUND_AVG_BW",
        "INBOUND_PEAK_BW",
        "INBOUND_PEAK_KB",
        "OUTBOUND_AVG_BW",
        "OUTBOUND_PEAK_BW",
        "OUTBOUND_PEAK_KB",
        "CONF",
        "BRIDGE_CONF",
        "OVS_BRIDGE_CONF",
        "IP_LINK_CONF",
        "EXTERNAL",
        "VCENTER_NET_REF",
        "VCENTER_SWITCH_NAME",
        "VCENTER_SWITCH_NPORTS",
        "VCENTER_PORTGROUP_TYPE",
        "VCENTER_CCR_REF",
        "VCENTER_INSTANCE_ID",
    )
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
    include opennebula_rpc_service
    "env" : string = 'prod' with match (SELF, '^(prod|dev)$')
    "tmpdir" : absolute_file_path = '/var/tmp'
    "host" : type_ipv4 = '127.0.0.1'
    "port" : type_port = 9869
    "sessions" : string = 'memory' with match (SELF, '^(memory|memcache)$')
    "memcache_host" : string = 'localhost'
    "memcache_port" : type_port = 11211
    "memcache_namespace" : string = 'opennebula.sunstone'
    "debug_level" : long (0..3) = 3
    "auth" : string = 'opennebula' with match (SELF, '^(sunstone|opennebula|x509|remote)$')
    @{This value needs to match `window.location.origin` evaluated by the User Agent
    during registration and authentication ceremonies. Remember that WebAuthn
    requires TLS on anything else than localhost}
    "webauthn_origin" : type_absoluteURI = 'http://localhost:9869'
    @{Relying Party name for display purposes}
    "webauthn_rpname" : string = 'OpenNebula Cloud'
    "encode_user_password" ? boolean
    "vnc_proxy_port" : type_port = 29876
    "vnc_proxy_support_wss" : string = 'no' with match (SELF, '^(no|yes|only)$')
    "vnc_proxy_cert" : string = ''
    "vnc_proxy_key" : string = ''
    "vnc_proxy_ipv6" : boolean = false
    "lang" : string = 'en_US'
    "table_order" : string = 'desc' with match (SELF, '^(desc|asc)$')
    @{Set default views directory}
    "mode" : string = 'mixed'
    "marketplace_username" ? string
    "marketplace_password" ? string
    "marketplace_url" : type_absoluteURI = 'http://marketplace.opennebula.io/'
    "oneflow_server" : type_absoluteURI = 'http://localhost:2474/'
    "instance_types" : opennebula_instance_types[] = list (
        dict("name", "small-x1", "cpu", 1, "vcpu", 1, "memory", 128,
        "description", "Very small instance for testing purposes"),
        dict("name", "small-x2", "cpu", 2, "vcpu", 2, "memory", 512,
        "description", "Small instance for testing multi-core applications"),
        dict("name", "medium-x2", "cpu", 2, "vcpu", 2, "memory", 1024,
        "description", "General purpose instance for low-load servers"),
        dict("name", "medium-x4", "cpu", 4, "vcpu", 4, "memory", 2048,
        "description", "General purpose instance for medium-load servers"),
        dict("name", "large-x4", "cpu", 4, "vcpu", 4, "memory", 4096,
        "description", "General purpose instance for servers"),
        dict("name", "large-x8", "cpu", 8, "vcpu", 8, "memory", 8192,
        "description", "General purpose instance for high-load servers"),
    )
    @{List of Ruby files containing custom routes to be loaded}
    "routes" : string[] = list("oneflow", "vcenter", "support", "nsx")
    @{List of filesystems to offer when creating new image}
    "support_fs" : string[] = list("ext4", "ext3", "ext2", "xfs")
};

@documentation{
Type that sets the OpenNebula
oneflow-server.conf file
}
type opennebula_oneflow = {
    include opennebula_rpc_service
    @{host where OneFlow server will run}
    "host" : type_ipv4 = '127.0.0.1'
    @{port where OneFlow server will run}
    "port" : type_port = 2474
    @{time in seconds between Life Cycle Manager steps}
    "lcm_interval" : long = 30
    @{default cooldown period after a scale operation, in seconds}
    "default_cooldown" : long = 300
    @{default shutdown action}
    "shutdown_action" : string = 'terminate' with match (SELF, '^(terminate|terminate-hard)$')
    @{default numner of virtual machines that will receive the given call in each interval
    defined by action_period, when an action is performed on a role}
    "action_number" : long(1..) = 1
    "action_period" : long(1..) = 60
    @{default name for the Virtual Machines created by OneFlow.
    You can use any of the following placeholders:
        $SERVICE_ID
        $SERVICE_NAME
        $ROLE_NAME
        $VM_NUMBER
    }
    "vm_name_template" : string = '$ROLE_NAME_$VM_NUMBER_(service_$SERVICE_ID)'
    @{log debug level
        0 = ERROR
        1 = WARNING
        2 = INFO
        3 = DEBUG
    }
    "debug_level" : long(0..3) = 2
    @{Endpoint for ZeroMQ subscriptions}
    "subscriber_endpoint" : string = 'tcp://localhost:2101'
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
Type that sets the OpenNebula
VNM (Virtual Network Manager) configuration file on the nodes
}
type opennebula_vnm_conf = {
    @{set to true to check that no other vlans are connected to the bridge.
     Works with 802.1Q and VXLAN.}
    "validate_vlan_id" : boolean = false
    @{enable ARP Cache Poisoning Prevention Rules for Open vSwitch.}
    "arp_cache_poisoning" : boolean = true
    @{base multicast address for each VLAN. The mc address is :vxlan_mc + :vlan_id.
    Used by VXLAN.}
    "vxlan_mc" : type_ipv4 = '239.0.0.0'
    @{Time To Live (TTL) should be > 1 in routed multicast networks (IGMP).
    Used by VXLAN.}
    "vxlan_ttl" : long = 16
};

@documentation{
Type that sets the OpenNebula conf
to contact to ONE RPC server
}
type opennebula_rpc = {
    "port" : type_port = 2633
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
    "groups" ? string[]
    "hosts" ? string[]
    "clusters" ? string[]
    "vmgroups" ? string[]
};

@documentation{
Type that sets the OpenNebula
pci.conf file
}
type opennebula_pci = {
    @{
    This option specifies the main filters for PCI card monitoring. The format
    is the same as used by lspci to filter on PCI card by vendor:device(:class)
    identification. Several filters can be added as a list, or separated
    by commas. The NULL filter will retrieve all PCI cards.

    From lspci help:
        -d [<vendor>]:[<device>][:<class>]
            Show only devices with specified vendor, device and  class  ID.
            The  ID's  are given in hexadecimal and may be omitted or given
            as "*", both meaning "any value"

    For example:
    :filter:
      - '10de:*'      # all NVIDIA VGA cards
      - '10de:11bf'   # only GK104GL [GRID K2]
      - '*:10d3'      # only 82574L Gigabit Network cards
      - '8086::0c03'  # only Intel USB controllers
    or
    :filter: '*:*'    # all devices
    or
    :filter: '0:0'    # no devices

    No devices filter is set by default.
    }
    "filter" : string[] = list('0:0')
    @{
    The PCI cards list restricted by the :filter option above can be even more
    filtered by the list of exact PCI addresses (bus:device.func).

    For example:
        :short_address:
            - '07:00.0'
            - '06:00.0'
    }
    "short_address" ? string[]
    @{
    The PCI cards list restricted by the :filter option above can be even more
    filtered by matching the device name against the list of regular expression
    case-insensitive patterns.

    For example:
        :device_name:
            - 'Virtual Function'
            - 'Gigabit Network'
            - 'USB.*Host Controller'
            - '^MegaRAID'
    }
    "device_name" ? string[]
    @{
    List of NVIDIA vendor IDs, these are used to recognize PCI devices from
    NVIDIA and use vGPU feature.

    For example:
        :nvidia_vendors:
            - '10de'

    On the other hand set an empty list to use full GPU PCI PT with NVIDIA cards:
        :nvidia_vendors: []
    }
    "nvidia_vendors" ? string[]
};

@documentation{
Type to define ONE basic resources
datastores, vnets, hosts names, etc
}
type component_opennebula = {
    include structure_component
    'datastores' ? opennebula_datastore{}
    'groups' ? opennebula_group{}
    'users' ? opennebula_user{}
    'vnets' ? opennebula_vnet{}
    'clusters' ? opennebula_cluster{}
    'vmgroups' ? opennebula_vmgroup{}
    'hosts' ? opennebula_host{}
    'rpc' ? opennebula_rpc
    'untouchables' ? opennebula_untouchables
    'oned' ? opennebula_oned
    'monitord' ? opennebula_monitord
    'sunstone' ? opennebula_sunstone
    'oneflow' ? opennebula_oneflow
    'kvmrc' ? opennebula_kvmrc
    'sched' ? opennebula_sched
    @{set pci pt filter configuration}
    'pci' ? opennebula_pci
    @{set vnm remote configuration}
    'vnm_conf' ? opennebula_vnm_conf
    @{set ssh host multiplex options}
    'ssh_multiplex' : boolean = true
    @{in some cases (such a Sunstone standalone configuration with apache),
    some OpenNebula configuration files should be accessible by a different group (as apache).
    This variable sets the group name to change these files permissions.}
    'cfg_group' ? string
} = dict();
