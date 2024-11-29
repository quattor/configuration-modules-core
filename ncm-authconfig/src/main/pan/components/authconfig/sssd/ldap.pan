# ${license-info}
# ${developer-info}
# ${author-info}

@{
    Contains the data structure describing the SSSD LDAP provider
}
declaration template components/authconfig/sssd/ldap;

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
    "authtok_type" : choice('password', 'obfuscated_password') = 'password'
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
    "uri" ? type_absoluteURI[]
    "backup_uri" ? type_absoluteURI[]
    "search_base" ? string
    "schema" : choice('IPA', 'AD', 'rfc2307', 'rfc2307bis') = 'rfc2307'
    "service" ? sssd_ldap_service

    "krb5_backup_server" ? string
    "krb5_canonicalize" ? boolean
    "krb5_realm" ? string
    "krb5_server" ? string
    "access_filter" ? string
    "access_order" : choice('filter', 'expire', 'authorized_service', 'host') = 'filter'
    "connection_expire_timeout" : long = 900
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
    "id_mapping" ? boolean = false
    "network_timeout" : long = 6
    "ns_account_lock" ? string
    "offline_timeout" ? long
    "opt_timeout" : long = 6
    "page_size" : long = 1000
    "purge_cache_timeout" : long = 10800
    "pwd_policy" : string = "none"
    "referrals" ? boolean
    "rootdse_last_usn" ? string
    "search_timeout" : long = 6
    "account_expire_policy" ? choice('shadow', 'ad', 'rhds', 'ipa', '389ds', 'nds')
};
