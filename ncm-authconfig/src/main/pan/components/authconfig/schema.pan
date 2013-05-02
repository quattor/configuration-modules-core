# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/authconfig/schema;

include { 'quattor/schema' };
include { 'pan/types' };

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

type authconfig_sssd_domain  = extensible {
    "acccess_provider" : string with match(SELF, "^(simple|ldap)$")
};

@{
    Simple access provider for SSSD.  See the sssd-simple man page.
}
type authconfig_sssd_simple = {
    "acccess_provider" : string = "simple"
    "allow_users" ? string[]
    "deny_users" ? string[]
    "allow_groups" ? string[]
    "deny_groups" ? string[]
};

type ldap_schema = string with match(SELF, "^(IPA|AD|rfc2307|rfc2307bis") ||
    error ("LDAP schema must be valid according to sssd-ldap: " + SELF);

type ldap_authok = string with match(SELF, "^(obfuscated_)?password") ||
    error ("LDAP authok must be valid according to sssd-ldap: " + SELF);

type ldap_req_checks = string with match(SELF, "^(never|allow|try|demand|hard)$") ||
    error ("LDAP certificate requests must be valid acording to ssd-ldap: " + SELF);

type ldap_deref = string with match(SELF, "^(never|searching|finding|always)$") ||
    error ("Invalid LDAP alias dereferencing method: " + SELF);

@{
    LDAP access provider for SSSD.  See the sssd-ldap man page.
    Timeouts are expressed in seconds.
}
type authconfig_sssd_ldap = {
    "access_provider" : string = "ldap"
    "ldap_uri" :  type_absoluteURI[]
    "ldap_backup_uri" ?  type_absoluteURI[]
    "ldap_chpass_uri" ? type_absoluteURI[]
    "ldap_chpass_backup_uri" ? type_absoluteURI[]
    "ldap_search_base" ?  string
    "ldap_schema" : ldap_schema = "rfc2307"
    "ldap_default_bind_dn" ?  string
    "ldap_default_authtok_type" : ldap_authok = "password"
    "ldap_default_authtok" ?  string
    "ldap_network_timeout" : long = 6
    "ldap_use_object_class" : string = "posixAccount"
    "ldap_user_uid_number" : string = "uidNumber"
    "ldap_user_gid_number" : string = "gidNumber"
    "ldap_user_gecos" : string = "gecos"
    "ldap_user_home_directory" : string = "homeDirectory"
    "ldap_user_shell" : string = "loginShell"
    "ldap_user_uuid" : string = "nsUniqueId"
    "ldap_user_objectsid" ? string
    "ldap_user_modify_timestamp" : string = "modifyTimestamp"
    "ldap_user_shadow_last_change" : string = "shadowLastChange"
    "ldap_user_shadow_min" : string = "shadowMin"
    "ldap_user_shadow_max" : string = "shadowMax"
    "ldap_user_shadow_warning" : string = "shadowWarning"
    "ldap_user_shadow_inactive" : string = "shadowInactive"
    "ldap_user_shadow_expire" : string = "shadowExpire"
    "ldap_user_krb_last_pwd_change" : string = "krbLastPwdChange"
    "ldap_user_krb_password_expiration" : string = "krbPasswordExpiration"
    "ldap_user_ad_account_expires" : string = "accountExpires"
    "ldap_user_ad_user_account_control" : string = "userAccountControl"
    "ldap_ns_account_lock" : string = "nsAccountLock"
    "ldap_user_nds_login_disabled" : string = "loginDisabled"
    "ldap_user_nds_login_expiration_time" : string = "loginDisabled"
    "ldap_user_nds_login_allowed_time_map" : string = "loginAllowedTimeMap"
    "ldap_user_principal" : string = "krbPrincipalName"
    "ldap_user_ssh_public_key" ? string
    "ldap_force_upper_case_realm" : boolean = false
    "ldap_enumeration_refresh_timeout" : long = 300
    "ldap_purge_cache_timeout" : long = 10800
    "ldap_user_fullname" : string = "cn"
    "ldap_user_member_of" : string = "memberOf"
    "ldap_user_authorized_service" : string = "authorizedService"
    "ldap_user_authorized_host" : string = "host"
    "ldap_group_object_class" : string = "posixGroup"
    "ldap_group_name" : string = "cn"
    "ldap_group_gid_number" : string = "gidNumber"
    "ldap_group_member" : string = "memberuid"
    "ldap_group_uuid" : string = "nsUniqueId"
    "ldap_group_objectsid" ? string
    "ldap_group_modify_timestamp" : string = "modifyTimestamp"
    "ldap_group_nesting_level" : long = 2
    "ldap_groups_use_matching_rule_in_chain" ? boolean
    "ldap_netgroup_object_class" : string = "nisNetgroup"
    "ldap_netgroup_name" : string = "cn"
    "ldap_netgroup_member" : string = "memberNisNetgroup"
    "ldap_netgroup_triple" : string = "nisNetgroupTriple"
    "ldap_netgroup_uuid" : string = "nsUniqueId"
    "ldap_netgroup_modify_timestamp" : string = "modifyTimestamp"
    "ldap_service_object_class" : string = "ipService"
    "ldap_service_name" : string = "cn"
    "ldap_service_port" : string = "ipServicePort"
    "ldap_service_proto" : string = "ipServiceProtocol"
    "ldap_service_search_base" ? string
    "ldap_search_timeout" : long = 6
    "ldap_enumeration_search_timeout" : long = 60
    "ldap_id_mapping" : boolean = false
    "ldap_sasl_mech" ? string
    "ldap_sasl_authid" ? string
    "ldap_sasl_realm" ? string
    "ldap_sasl_canonicalize" ? boolean
    "ldap_krb5_keytab" ? string
    "ldap_krb5_init_creds" ? boolean
    "ldap_pwd_policy" : string = "none"



    "ldap_opt_timeout" :  long = 6
    "ldap_offline_timeout" ? long
    "ldap_tls_cacert" ?  string
    "ldap_tls_cacertdir" ?  string
    "ldap_tls_cert" ?  string
    "ldap_tls_key" ?  string
    "ldap_tls_cipher_suite" ?  string[]
    "ldap_tls_reqcert" ? ldap_req_checks = "hard"
    "ldap_sasl_mech" ?  string
    "ldap_sasl_authid" ?  string
    "krb5_server" ?  string[]
    "krb5_backup_server" ?  string[]
    "krb5_realm" ?  string[]
    "krb5_canonicalize" ?  boolean[]
    "ldap_krb5_keytab" ?  string
    "ldap_krb5_init_creds" ?  boolean[]
    "ldap_entry_usn" ?  string[]
    "ldap_rootdse_last_usn" ?  string[]
    "ldap_referrals" :  boolean = true
    "ldap_krb5_ticket_lifetime" ?  long
    "ldap_dns_service_name" ?  string
    "ldap_deref" : ldap_deref = "never"
    "ldap_page_size" :  long = 1000
    "ldap_deref_threshold" ?  long
    "ldap_sasl_canonicalize" ?  boolean[]
    "ldap_sasl_minssf" ?  long
    "ldap_connection_expire_timeout" :  long = 900
    "ldap_disable_paging" :  boolean = false
};

type authconfig_method_sssd_type = {
    include authconfig_method_generic_type
    "nssonly" : boolean = false
    "domains" : authconfig_sssd_domain{}
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
