# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/authconfig/schema;

include { 'quattor/schema' };
include { 'pan/types' };

include {'components/${project.artifactId}/sssd-user'};
include {'components/${project.artifactId}/sssd-sudo'};
include {'components/${project.artifactId}/sssd-sasl'};
include {'components/${project.artifactId}/sssd-tls'};

type yesnostring = string with match(SELF,"yes|no");

type authconfig_pamadditions_line_type = {
  "order"       : string with match(SELF,"first|last")
  "entry"       : string
};

type authconfig_pamadditions_type = {
  "conffile"	: string = "/etc/pam.d/system_auth"
  "section"     : string with match(SELF,"auth|account|password|session")
  "lines"       : authconfig_pamadditions_line_type[]
};

type authconfig_method_generic_type = {
  "enable"	: boolean = false
};

type authconfig_method_afs_type = {
  include authconfig_method_generic_type
  "cell"	: type_fqdn
};

type authconfig_method_ldap_tls_type = {
  "enable"	: boolean = false
  "peercheck"	: boolean = false
  "cacertfile"	? string
  "cacertdir"	? string
  "ciphers"	? string
  "reqcert"     : string = "never"
};

type authconfig_method_ldap_timeouts_type = {
  "idle"	? long
  "bind"	? long
  "search"	? long
};

type authconfig_nss_map_objectclass = {
  "posixAccount"  : string = "user"
  "shadowAccount"  : string = "user"
  "posixGroup"	 : string = "group"
};

type authconfig_nss_map_attribute = {
  "uid"	: string = "sAMAccountName"
  "homeDirectory"	: string = "unixHomeDirectory"
  "uniqueMember"	: string = "member"
  "uidNumber"   ? string
  "gidNumber"   ? string
  "cn"  ? string
  "userPassword"    ? string
  "loginShell"          ? string
  "gecos"               ? string
};

type authconfig_nss_override_attribute_value = {
  "unixHomeDirectory"	? string
  "loginShell"      	? string
  "gecos"           	? string
  "gidNumber"           ? long
};

type connect_policy = string with (SELF=="oneshot" || SELF=="persistent");

type authconfig_method_ldap_type = {
  include authconfig_method_generic_type
  "servers"	? string[]
  "nssonly"	? boolean
  "conffile"	: string = "/etc/ldap.conf"
  "basedn"	: string
  "tls"		? authconfig_method_ldap_tls_type
  "binddn"	? string
  "bindpw"	? string
  "scope"   ? string
  "rootbinddn"	? string
  "port"	? type_port
  "timeouts"	? authconfig_method_ldap_timeouts_type
  "pam_filter"	: string = "objectclass=posixAccount"
  "pam_login_attribute"	? string
  "pam_lookup_policy" ? string
  "pam_password"    ? string
  "pam_groupdn"	? string
  "pam_member_attribute"	? string
  "pam_check_service_attr"	? string
  "pam_check_host_attr"	? string
  "pam_min_uid"	? long
  "pam_max_uid"	? long
  "nss_base_passwd"	? string
  "nss_base_group"	? string
  "nss_base_shadow"	? string
  "bind_policy"	? string
  "ssl"	: string = "start_tls"
  "nss_map_objectclass"            ? authconfig_nss_map_objectclass
  "nss_map_attribute"              ? authconfig_nss_map_attribute
  "nss_override_attribute_value"   ? authconfig_nss_override_attribute_value
  "nss_initgroups_ignoreusers"     ? string
  "debug"                          ? long
  "log_dir"                        ? string
  "nss_paged_results"              : yesnostring = "yes"
  "pagesize"                       ? long
  "nss_connect_policy"             ? connect_policy = "oneshot"
};

type authconfig_method_nis_type = {
  include authconfig_method_generic_type
  "servers"	: type_hostname[]
  "domain"	: string
};

type authconfig_method_krb5_type = {
  include authconfig_method_generic_type
  "kdcs"	? type_hostname[]
  "adminservers"	? type_hostname[]
  "realm"	: string
};

type authconfig_method_smb_type = {
  include authconfig_method_generic_type
  "servers"     : type_hostname[]
  "workgroup"	: string
};

type authconfig_method_hesiod_type = {
  include authconfig_method_generic_type
  "lhs"		: string
  "rhs"		: string
};

type authconfig_method_files_type = {
  include authconfig_method_generic_type
};

# LDAP attributes, as per RFC 2307
type authconfig_nslcd_map_attributes = {
    "uid"       ? string
    "gid"       ? string
    "uidNumber" ? string
    "gidNumber" ? string
    "gecos" ? string
    "homeDirectory" ? string
    "loginShell" ? string
    "shadowLastChange" ? string
    "shadowMin" ? string
    "shadowMax" ? string
    "shadowWarning" ? string
    "shadowInactive" ? string
    "shadowExpire" ? string
    "shadowFlag" ? string
    "memberUid" ? string
    "memberNisNetgroup" ? string
    "nisNetgroupTriple" ? string
    "ipServicePort" ? string
    "ipServiceProtocol" ? string
    "ipProtocolNumber" ? string
    "oncRpcNumber" ? string
    "ipHostNumber" ? string
    "ipNetworkNumber" ? string
    "ipNetmaskNumber" ? string
    "macAddress" ? string
    "bootParameter" ? string
    "bootFile" ? string
    "nisMapName" ? string
    "nisMapEntry" ? string
    "uniqueMember" ? string
};


type authconfig_nslcd_maps = {
    "alias" ? authconfig_nslcd_map_attributes
    "ethers" ? authconfig_nslcd_map_attributes
    "group" ? authconfig_nslcd_map_attributes
    "host"  ? authconfig_nslcd_map_attributes
    "netgroup" ? authconfig_nslcd_map_attributes
    "networks" ? authconfig_nslcd_map_attributes
    "passwd"   ? authconfig_nslcd_map_attributes
    "protocols" ? authconfig_nslcd_map_attributes
    "service"  ? authconfig_nslcd_map_attributes
    "shadow"   ? authconfig_nslcd_map_attributes
};

type authconfig_nslcd_filter = {
    "alias" ? string
    "ethers" ? string
    "group" ? string
    "host"  ? string
    "netgroup" ? string
    "networks" ? string
    "passwd"   ? string
    "protocols" ? string
    "service"  ? string
    "shadow"   ? string
};

type authconfig_method_nslcd_type = {
    include authconfig_method_generic_type
    "threads" ? long
    "uid"     ? string
    "gid"     ? string
    "uri"     ? type_hostURI[]
    "binddn"  ? string
    "rootpwmoddn" ? string
    "krb5_ccname" ? string
    "basedn"  : string
    "base"    : authconfig_nslcd_filter
    "scope"   ? string
    "deref"   ? string with match(SELF, "^never|searching|finding|always$")
    "filter"  ? authconfig_nslcd_filter
    "map"     ? authconfig_nslcd_maps
    "bind_timelimit" ? long
    "timelimit" ? long
    "idle_timelimit" ? long
    "reconnect_sleeptime" ? long
    "reconnect_retrytime" ? long
    "ssl"     ? string with match(SELF, "^on|off|start_tls$")
    "tls_reqcert" ? string with match(SELF, "^never|allow|try|demand|hard$")
    "tls_cacertdir" ? string
    "tls_randfile" ? string
    "tls_ciphers" ? string[]
    "tls_cert" ? string
    "tls_cert" ? string
    "tls_key" ? string
    "pagesize" ? long
    "nss_initgroups_ignoreusers" ? string[]
    "pam_authz_search" ? string
    "bindpw" ? string
};

@{
    Valid SSSD providers.  For now we only implement ldap, simple and local
}
type sssd_provider_string = string with match(SELF, "^(ldap|simple|local)$");


@{
    Simple access provider for SSSD.  See the sssd-simple man page.
}
type authconfig_sssd_simple = {
    "allow_users" ? string[]
    "deny_users" ? string[]
    "allow_groups" ? string[]
    "deny_groups" ? string[]
};

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
    "bind_dn" ?  string
    "authtok_type" : ldap_authok = "password"
    "authtok" ?  string
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
    "entry_object_class" : string = "automountMap"
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
    "uri" :  type_absoluteURI[]
    "backup_uri" ?  type_absoluteURI[]
    "search_base" ?  string
    "schema" : ldap_schema = "rfc2307"
    "service" ? sssd_ldap_service

    "krb5_backup_server" ?  string
    "krb5_canonicalize" ?  boolean
    "krb5_realm" ?  string[]
    "krb5_server" ?  string
    "access_filter" ? string with match(SELF, "^(shadow|ad|rhds|ipa|389ds|nds)$")
    "access_order" : ldap_order = "filter"
    "connection_expire_timeout" :  long = 900
    "deref" : ldap_deref = "never"
    "deref" ? string
    "deref_threshold" ?  long
    "disable_paging" :  boolean = false
    "dns_service_name" ?  string
    "entry_usn" ?  string[]
    "enumeration_refresh_timeout" : long = 300
    "enumeration_search_timeout" : long = 60
    "force_upper_case_realm" : boolean = false
    "groups_use_matching_rule_in_chain" ? boolean
    "id_use_start_tls" ? boolean
    "id_mapping" : boolean = false
    "network_timeout" : long = 6
    "ns_account_lock" : string = "nsAccountLock"
    "offline_timeout" ? long
    "opt_timeout" :  long = 6
    "page_size" :  long = 1000
    "purge_cache_timeout" : long = 10800
    "pwd_policy" : string = "none"
    "referrals" :  boolean = true
    "rootdse_last_usn" ?  string
    "search_timeout" : long = 6
    "use_object_class" : string = "posixAccount"
};

type sssd_service = string with match(SELF, "^(nss|pam|sudo|autofs|ssh|pac)$");

type sssd_global = {
    "config_file_version" : long = 2
    "services" : sssd_service[]
    "reconnection_retries" : long = 3
    "re_expression" ?  string
    "full_name_format" ? string
    "try_inotify" : boolean = true
    "krb5_rcache_dir" ? string
    "default_domain_suffix" ? string
};

type sssd_pam = {
    "offline_credentials_expiration" : long = 0
    "offline_failed_login_attempts" : long = 0
    "offline_failed_login_delay" : long =  5
    "pam_verbosity" : long =  1
    "pam_id_timeout" : long =  5
    "pam_pwd_expiration_warning" : long =  0
    "get_domains_timeout" : long =  60
};

type sssd_nss = {
    "enum_cache_timeout" : long = 120
    "entry_cache_nowait_percentage" ? long
    "entry_negative_timeout" : long = 15
    "filter_users" : string = "root"
    "filter_users_in_groups" : boolean = true
    "filter_groups" : string = "root"
};

type authconfig_sssd_local = {
       "default_shell" : string = "/bin/bash"
       "base_directory" : string = "/home"
       "create_homedir" : boolean = true
       "remove_homedir" : boolean = true
       "homedir_umask" : long = 077
       "skel_dir" : string = "/etc/skel"
       "mail_dir" : string = "/var/mail"
       "userdel_cmd" ? string
};

type authconfig_sssd_domain  = extensible {
    "ldap" ? authconfig_sssd_ldap
    "simple" ? authconfig_sssd_simple
    "local" ? authconfig_sssd_local
    "access_provider" ? sssd_provider_string
    "id_provider" ? sssd_provider_string
    "auth_provider" ? sssd_provider_string
    "chpass_provider" ? sssd_provider_string
    "sudo_provider" ? string
    "selinux_provider" ? string
    "subdomains_provider" ? string
    "autofs_provider" ? string
    "hostid_provider" ? string
    "re_expression" : string = "(?P<name>[^@]+)@?(?P<domain>[^@]*$)"
    "full_name_format" : string = "%1$s@%2$s"
    "lookup_family_order" : string = "ipv4_first"
    "dns_resolver_timeout" : long = 5
    "dns_discovery_domain" ? string
    "override_gid" ? long
    "case_sensitive" : boolean = true
    "proxy_fast_alias" : boolean = false
    "subdomain_homedir" : string = "/home/%d/%u"
    "proxy_pam_target" ? string
    "proxy_lib_name" ? string
    "min_id" : long = 1
    "max_id" : long = 0
    "enumerate" : boolean = false
    "force_timeout" : long = 60
    "entry_cache_timeout" : long = 5400
    "entry_cache_user_timeout" ? long
    "entry_cache_group_timeout" ? long
    "entry_cache_netgroup_timeout" ? long
    "entry_cache_service_timeout" ? long
    "entry_cache_sudo_timeout" ? long
    "entry_cache_autofs_timeout" ? long
    "cache_credentials" : boolean = false
    "account_cache_expiration" : long = 0
    "pwd_expiration_warning" ? long

};
type authconfig_method_sssd_type = {
    include authconfig_method_generic_type
    "nssonly" : boolean = false
    "domains" : authconfig_sssd_domain{}
    "global" : sssd_global
    "pam" : sssd_pam
    "nss" : sssd_nss
};



type authconfig_method_type = {
  "files"	? authconfig_method_files_type
  "ldap"	? authconfig_method_ldap_type
  "nis"		? authconfig_method_nis_type
  "krb5"	? authconfig_method_krb5_type
  "smb"		? authconfig_method_smb_type
  "hesiod"	? authconfig_method_hesiod_type
  "afs"		? authconfig_method_afs_type
  "nslcd"       ? authconfig_method_nslcd_type
  "sssd"	? authconfig_method_sssd_type
};

type hash_string = string with match(SELF, "^(descrypt|md5|sha256|sha512)$");

type component_authconfig_type = {
  include structure_component
  "safemode"	: boolean = false
  "passalgorithm" : hash_string = "md5"
  "useshadow"	? boolean
  "usecache"	? boolean
  "enableforcelegacy"	: boolean = false
  "startstop"	? boolean
  "usemd5"      : boolean
  "method"	? authconfig_method_type

  "pamadditions" ? authconfig_pamadditions_type{}
};

bind "/software/components/authconfig" = component_authconfig_type;
