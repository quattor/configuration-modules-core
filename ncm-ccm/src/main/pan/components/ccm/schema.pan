${componentschema}

include 'quattor/types/component';
include 'pan/types';
include if_exists('components/accounts/functions');

@documentation {
    kerberos_principal_string is a string with format `principal[/component1[/component2[...]]]@REALM`
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
    if (! match(realm, '^[a-zA-Z][\w.-]*$')) {
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

type ccm_component = {
    include structure_component
    @{The location of the configuration file. Normally this should not be changed. Defaults to `/etc/ccm.conf`.}
    'configFile' : string = '/etc/ccm.conf'
    @{The URL for the machine's profile. You can use either the http or https protocols
      (the file protocol is also possible eg. for tests). (see ccm-fetch manpage)}
    'profile' : type_hostURI
    @{list of profile failover URL(s) in case the above is not working. (see ccm-fetch manpage)}
    'profile_failover' ? type_hostURI[]
    @{Turn on debugging. Defaults to 0.}
    'debug' : long(0..1) = 0
    @{Force fetching of the machine profile. Turning this on ignores the modification times. Defaults to 0. }
    'force' : long(0..1) = 0
    @{The root directory of the CCM cache.  Defaults to `/var/lib/ccm`.}
    'cache_root' : string = '/var/lib/ccm'
    @{The timeout for the download operation in seconds.  Defaults to 30.}
    'get_timeout' : long(0..) = 30
    @{Number of times to try to get the lock on the cache.  Defaults to 3.}
    'lock_retries' : long(0..) = 3
    @{Number of seconds to wait between attempts to acquire the lock.  Defaults to 30.}
    'lock_wait' : long(0..) = 30
    @{Number of times to try to get the context from the server.  Defaults to 3.}
    'retrieve_retries' : long(0..) = 3
    @{Number of seconds to wait between attempts to get the context from the server.  Defaults to 30.}
    'retrieve_wait' : long(0..) = 30
    @{The certificate file to use for an https protocol.}
    'cert_file' ? string
    @{The key file to use for an https protocol.}
    'key_file' ? string
    @{The CA file to use for an https protocol.}
    'ca_file' ? string
    @{The directory containing accepted CA certificates when using the https protocol.}
    'ca_dir' ? string
    @{Whether the profiles should be group-readable (value is the groupname).
      There is no default, and it is not allowed to set both C<group_readable> and enable C<world_readable>.}
    'group_readable' ? string with {
        if (path_exists('/software/components/accounts')) {
            is_user_or_group('group', SELF)
        } else {
            true;
        }}
    @{Whether the profiles should be world-readable. Defaults to 0. }
    'world_readable' : long(0..1) = 0
    @{If `profile` is not a URL, a profile url will be calculated from `base_url` and the local hostname.}
    'base_url' ? type_absoluteURI
    @{Format of the local database, must be `DB_File`, `CDB_File` or `GDBM_File`. Defaults to `GDBM_File`. }
    'dbformat' ? string with match(SELF, "^(DB_File|CDB_File|GDBM_File)$")
    @{Extract typed data from JSON profiles}
    'json_typed' ? boolean
    @{Create the tabcompletion file (during profile fetch)}
    'tabcompletion' ? boolean
    @{Number of old profiles to keep before purging}
    'keep_old' ? long(0..)
    @{Number of seconds before purging inactive profiles.}
    'purge_time' ? long(0..)
    @{Comma-separated list of kerberos principals to trust when using encrypted profiles}
    'trust' ? kerberos_principal_string[]
    @{Principal to use for Kerberos setup}
    'principal' ? kerberos_principal_string
    @{Keytab to use for Kerberos setup}
    'keytab' ? string
} with {
    if(is_defined(SELF['group_readable']) && SELF['world_readable'] == 1) {
        error("Cannot set both group_readable and enable world_readable for ccm");
    };
    true;
};
