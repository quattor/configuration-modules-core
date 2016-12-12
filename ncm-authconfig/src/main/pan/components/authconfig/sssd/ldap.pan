# ${license-info}
# ${developer-info}
# ${author-info}

@{
    Contains the data structure describing the SSSD LDAP provider
}

declaration template components/authconfig/sssd/ldap;

type ldap_schema = string with match(SELF, "^(IPA|AD|rfc2307|rfc2307bis)") ||
    error ("LDAP schema must be valid according to sssd-ldap: " + SELF);

type ldap_authok = string with match(SELF, "^(obfuscated_)?password") ||
    error ("LDAP authok must be valid according to sssd-ldap: " + SELF);

type ldap_deref = string with match(SELF, "^(never|searching|finding|always)$") ||
    error ("Invalid LDAP alias dereferencing method: " + SELF);

type ldap_order = string with match(SELF, "^(filter|expire|authorized_service|host)$");

@{
    LDAP chpass fields
}
type sssd_chpass = {
    "uri" ? type_absoluteURI[]
    "backup_uri" ? type_absoluteURI[]
    "dns_service_name" ? string
    "update_last_change" : boolean = false
};

type sssd_ldap_defaults = {
    "bind_dn" ? string
    "authtok_type" : ldap_authok = "password"
    "authtok" ? string
};

@{
    LDAP netgroup fields
}
type sssd_netgroup = {
    "object_class" : string = "nisNetgroup"
    "name" : string = "cn"
    "member" : string = "memberNisNetgroup"
    "triple" : string = "nisNetgroupTriple"
    "uuid" : string = "nsUniqueId"
    "modify_timestamp" : string = "modifyTimestamp"
    "search_base" ? string
};

@{
    LDAP autofs fields
}
type sssd_autofs = {
    "map_object_class" : string = "automountMap"
    "map_name" : string = "ou"
    "entry_object_class" : string = "automount"
    "entry_key" : string = "cn"
    "entry_value" : string = "automountInformation"
    "search_base" ? string
};

@{
    LDAP IP service fields
}
type sssd_ldap_service = {
    "object_class" : string = "ipService"
    "name" : string = "cn"
    "port" : string = "ipServicePort"
    "proto" : string = "ipServiceProtocol"
    "search_base" ? string
};

@{
    LDAP access provider for SSSD.  See the sssd-ldap man page.
    Timeouts are expressed in seconds.
}
type authconfig_sssd_ldap = {
    "user" : sssd_user
    "group" : sssd_group
    "chpass" ? sssd_chpass
    "default" : sssd_ldap_defaults
    "sasl" ? sssd_sasl
    "krb5" ? sssd_krb5
    "sudo" ? sssd_sudo
    "sudorule" ? sssd_sudorule
    "tls" ? sssd_tls
    "netgroup" ? sssd_netgroup
    "autofs" ? sssd_autofs
    "uri" : type_absoluteURI[]
    "backup_uri" ? type_absoluteURI[]
    "search_base" ? string
    "schema" : ldap_schema = "rfc2307"
    "service" ? sssd_ldap_service

    "krb5_backup_server" ? string
    "krb5_canonicalize" ? boolean
    "krb5_realm" ? string[]
    "krb5_server" ? string
    "access_filter" ? string
    "access_order" : ldap_order = "filter"
    "connection_expire_timeout" : long = 900
    "deref" : ldap_deref = "never"
    "deref" ? string
    "deref_threshold" ? long
    "disable_paging" : boolean = false
    "dns_service_name" ? string
    "entry_usn" ? string[]
    "enumeration_refresh_timeout" : long = 300
    "enumeration_search_timeout" : long = 60
    "force_upper_case_realm" : boolean = false
    "groups_use_matching_rule_in_chain" ? boolean
    "id_use_start_tls" ? boolean
    "id_mapping" : boolean = false
    "network_timeout" : long = 6
    "ns_account_lock" : string = "nsAccountLock"
    "offline_timeout" ? long
    "opt_timeout" : long = 6
    "page_size" : long = 1000
    "purge_cache_timeout" : long = 10800
    "pwd_policy" : string = "none"
    "referrals" : boolean = true
    "rootdse_last_usn" ? string
    "search_timeout" : long = 6
    "use_object_class" : string = "posixAccount"
    "account_expire_policy" ? string with match(SELF, "^(shadow|ad|rhds|ipa|389ds|nds)$")
};
