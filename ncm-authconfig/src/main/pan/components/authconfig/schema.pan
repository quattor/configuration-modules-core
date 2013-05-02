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

type authconfig_method_sssd_type = {
    include authconfig_method_generic_type
    "nssonly" : boolean = false
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
