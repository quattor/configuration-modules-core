declaration template metaconfig/ctdb/schema;

include 'pan/types';


@{ Checks for a valid network device @}
function is_interface_device = {
    if (exists(format("/system/network/interfaces/", ARGV[0]))) {
        return(true);
    };
    foreach(ifc;attr;value('/system/network/interfaces')) {
        if (attr['device'] == ARGV[0]){
            return(true);
        };
    };
    return(false);
};

@{ type for a ctdb public address @}
type ctdb_public_address = {
    'network_name'          : type_network_name
    'network_interface'    : string with is_interface_device(SELF)
};

type ctdb_public_addresses = ctdb_public_address[];

type ctdb_nodes = type_ip[];

@{ type for configuring the ctdb config file @}
type ctdb_service = {
    'ctdb_debuglevel'           ? long(0..)
    'ctdb_logfile'              ? string
    'ctdb_manages_nfs'          ? boolean
    'ctdb_manages_samba'        ? boolean
    'ctdb_nfs_skip_share_check' ? boolean
    'ctdb_nodes'                ? string
    'ctdb_public_addresses'     ? string
    'ctdb_recovery_lock'        : string
    'ctdb_syslog'               ? boolean
    'nfs_hostname'              ? type_fqdn
    'nfs_server_mode'           ? string
    'prologue'                  ? string    
};

