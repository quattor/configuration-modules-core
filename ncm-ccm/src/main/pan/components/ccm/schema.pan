# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ccm/schema;

include {'quattor/schema'};
include {'pan/types'};

type component_ccm = {
    include structure_component
    'configFile'       : string = '/etc/ccm.conf'
    'profile'          : type_hostURI
    'profile_failover' ? type_hostURI
    'context'          ? type_hostURI
    'debug'            : long(0..1) = 0
    'force'            : long(0..1) = 0
    'preprocessor'     ? string
    'cache_root'       : string = '/var/lib/ccm'
    'get_timeout'      : long(0..) = 30
    'lock_retries'     : long(0..) = 3
    'lock_wait'        : long(0..) = 30
    'retrieve_retries' : long(0..) = 3
    'retrieve_wait'    : long(0..) = 30
    'cert_file'        ? string
    'key_file'         ? string
    'ca_file'          ? string
    'ca_dir'           ? string
    'world_readable'   : long(0..1) = 0
    'base_url'         ? type_absoluteURI
    'dbformat'         ? string with match(SELF, "^(DB_File|CDB_File|GDBM_File)$")
    'trust'            ? string
};

bind '/software/components/ccm' = component_ccm;
