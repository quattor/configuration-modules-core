# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ccm/schema;

include 'quattor/types/component';
include 'pan/types';
include 'components/accounts/functions';

@documentation {
    kerberos_principal_string is a string with format principal[/component1[/component2[...]]]@REALM
}
type kerberos_principal_string = string with {
    # yes, they are really called components
    # p = principal
    # r = realm
    # c = remainder of components
    # first split on realm separator
    pc_r = split('@', SELF);

    # need a principal and a realm
    len = length(pc_r);
    if (len < 2) {
        error("Requires at least a principal and a realm, got " + SELF);
    };

    p_c = split('/', pc_r[0]);
    len_c = length(p_c) - 1;
    principal = p_c[0];

    # username, only \w allowed
    if (! match(principal, '^\w+$')) {
        error("Not a valid principal " + principal);
    };

    realm = pc_r[len-1];
    # uppercase REALM
    if (! match(realm, '^[a-zA-Z][a-zA-Z.-_]*$')) {
        error("Not a valid realm " + realm);
    };

    if (len_c > 0) {
        components = splice(p_c, 0, 1);
        foreach (idx; component; components) {
            if (!match(component, '^\w[\w.-]*$')) {
                error("Not a valid component " + component);
            };
        };
    };

    true;
};


type component_ccm = {
    include structure_component
    'configFile'       : string = '/etc/ccm.conf'
    'profile'          : type_hostURI
    'profile_failover' ? type_hostURI[]
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
    'group_readable'   ? defined_group
    'world_readable'   : long(0..1) = 0
    'base_url'         ? type_absoluteURI
    'dbformat'         ? string with match(SELF, "^(DB_File|CDB_File|GDBM_File)$")
    'json_typed'       ? boolean
    'tabcompletion'    ? boolean
    'keep_old'         ? long(0..)
    'trust'            ? kerberos_principal_string[]
    'principal'        ? kerberos_principal_string
    'keytab'           ? string
} with {
    if(is_defined(SELF['group_readable']) && SELF['world_readable'] == 1) {
        error("Cannot set both group_readable and enable world_readable for ccm");
    };
    true;
};
