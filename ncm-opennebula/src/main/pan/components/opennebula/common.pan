# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/opennebula/common;


type opennebula_device_prefix = choice('hd', 'sd', 'vd');
type opennebula_vdc_rules = choice('USE', 'MANAGE', 'ADMIN');

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
    true;
};

@documentation{
check if a specific type of datastore has the right attributes
}
function is_consistent_datastore = {
    ds = ARGV[0];
    if (ds['ds_mad'] == 'ceph') {
        if (ds['tm_mad'] != 'ceph') {
            error("for a ceph datastore both ds_mad and tm_mad should have value 'ceph'");
        };
        req = list('disk_type', 'bridge_list', 'ceph_host', 'ceph_secret', 'ceph_user', 'ceph_user_key', 'pool_name');
        foreach(idx; attr; req) {
            if(!exists(ds[attr])) {
                error(format("Invalid ceph datastore! Expected '%s' ", attr));
            };
        };
    };
    if (ds['ds_mad'] == 'fs') {
        if (ds['tm_mad'] != 'shared') {
            error("for a fs datastore only 'shared' tm_mad is supported for the moment");
        };
    };
    if (ds['type'] == 'SYSTEM_DS') {
        if (ds['tm_mad'] == 'ceph') {
            error("system datastores do not support '%s' TM_MAD", ds['tm_mad']);
        };
    };
    if (ds['ds_mad'] == 'dev') {
        if (ds['tm_mad'] != 'dev') {
            error("for a RDM datastore both ds_mad and tm_mad should have value 'dev'");
        };
        if(!exists(ds['disk_type'])) {
            error("Invalid RDM datastore! Expected 'disk_type'");
        };
    };
    # Checks for other types can be added here
    true;
};

@documentation{
check if a specific type of vnet has the right attributes
}
function is_consistent_vnet = {
    vn = ARGV[0];
    # phydev is only required by vxlan networks
    if (vn['vn_mad'] == 'vxlan') {
        if (!exists(vn['phydev'])) {
            error("VXLAN vnet requires 'phydev' value to attach a bridge");
        };
    # if not the bridge is mandatory
    } else {
        if (!exists(vn['bridge'])) {
            error(format("vnet with 'vn_mad' '%s' requires a 'bridge' value", vn['vn_mad']));
        };
    };
    true;
};

type opennebula_mysql_db = {
    "server" ? string
    "port" ? type_port
    "user" ? string
    "passwd" ? string
    "db_name" ? string
    @{Number of DB connections. The DB needs to be configured to
    support oned + monitord connections.}
    "connections" : long(1..) = 25
    @{Compare strings using BINARY clause makes name searches case sensitive}
    "compare_binary" : boolean = false
};

type opennebula_db = {
    include opennebula_mysql_db
    "backend" : string with match(SELF, "^(mysql|sqlite)$")
} with is_consistent_database(SELF);

type opennebula_log = {
    @{Configuration for the logging system
    file: to log in the sched.log file
    syslog: to use the syslog facilities}
    "system" : string = 'file' with match (SELF, '^(file|syslog)$')
    @{debug_level:
    0 = ERROR
    1 = WARNING
    2 = INFO
    3 = DEBUG   Includes general scheduling information (default)
    4 = DDEBUG  Includes time taken for each step
    5 = DDDEBUG Includes detailed information about the scheduling
    decision, such as VM requirements, Host ranking for
    each VM, etc. This will impact the performance}
    "debug_level" : long(0..5) = 3
} = dict();

type opennebula_im = {
    "name" : string
    "executable" : string = 'one_im_ssh'
    "arguments" : string
    "sunstone_name" ? string
    @{Number of threads, i.e. number of hosts monitored at the same time}
    "threads" ? long(0..)
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
        'snapshot-create',
        'snapshot-delete',
    )
    "keep_snapshots" : boolean = true
} = dict();

@documentation{
type for opennebula service common RPC attributes.
}
type opennebula_rpc_service = {
    @{OpenNebula daemon RPC contact information}
    "one_xmlrpc" : type_absoluteURI = 'http://localhost:2633/RPC2'
    @{authentication driver to communicate with OpenNebula core}
    "core_auth" : string = 'cipher' with match (SELF, '^(cipher|x509)$')
};
