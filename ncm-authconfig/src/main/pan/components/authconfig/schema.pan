# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/authconfig/schema;

include { 'quattor/schema' };
include { 'pan/types' };

type authconfig_pamadditions_line_type = {
  "order"       : string with match(SELF,"first|last")
  "entry"       : string
};

type authconfig_pamadditions_type = {
  "conffile"	: string
  "section"     : string with match(SELF,"auth|account|password|session")
  "lines"       : authconfig_pamadditions_line_type[]
};

type authconfig_method_generic_type = {
  "enable"	: boolean
};

type authconfig_method_afs_type = {
  include authconfig_method_generic_type
  "cell"	: type_fqdn
};

type authconfig_method_ldap_tls_type = {
  "enable"	: boolean
  "peercheck"	? boolean
  "cacertfile"	? string
  "cacertdir"	? string
  "ciphers"	? string
  "reqcert" ? string
};

type authconfig_method_ldap_timeouts_type = {
  "idle"	? long
  "bind"	? long
  "search"	? long
};

type authconfig_nss_map_objectclass = {
  "posixAccount"  ? string
  "shadowAccount"	? string
  "posixGroup"	? string
};

type authconfig_nss_map_attribute = {
  "uid"	? string
  "homeDirectory"	? string
  "uniqueMember"	? string
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


type authconfig_method_ldap_type = {
  include authconfig_method_generic_type
  "servers"	: string[]
  "nssonly"	? boolean
  "conffile"	? string
  "basedn"	: string
  "tls"		? authconfig_method_ldap_tls_type
  "binddn"	? string
  "bindpw"	? string
  "scope"   ? string
  "rootbinddn"	? string
  "port"	? type_port
  "timeouts"	? authconfig_method_ldap_timeouts_type
  "pam_filter"	? string
  "pam_login_attribute"	? string
  "pam_password"    ? string
  "pam_groupdn"	? string
  "pam_member_attribute"	? string
  "pam_check_service_attr"	? string
  "pam_check_host_attr"	? string
  "pam_min_uid"	? long
  "pam_max_uid"	? long
  "nss_base_passwd"	? string
  "nss_base_group"	? string
  "bind_policy"	? string
  "ssl"	? string
  "nss_map_objectclass"            ? authconfig_nss_map_objectclass
  "nss_map_attribute"              ? authconfig_nss_map_attribute
  "nss_override_attribute_value"   ? authconfig_nss_override_attribute_value
  "nss_initgroups_ignoreusers"     ? string
  "debug"                          ? long
  "log_dir"                        ? string
  "nss_paged_results"              ? string with match(SELF,"yes|no")
  "pagesize"                       ? long
};

type authconfig_method_nis_type = {
  include authconfig_method_generic_type
  "servers"	: type_hostname[]
  "domain"	: string
};

type authconfig_method_krb5_type = {
  include authconfig_method_generic_type
  "kdcs"	: type_hostname[]
  "adminserver"	: type_hostname[]
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


type authconfig_method_type = {
  "files"	? authconfig_method_files_type 
  "ldap"	? authconfig_method_ldap_type
  "nis"		? authconfig_method_nis_type
  "krb5"	? authconfig_method_krb5_type
  "smb"		? authconfig_method_smb_type
  "hesiod"	? authconfig_method_hesiod_type
  "afs"		? authconfig_method_afs_type
};

type component_authconfig_type = {
  include structure_component
  "safemode"	? boolean
  "usemd5"	? boolean
  "useshadow"	? boolean
  "usecache"	? boolean
  "startstop"	? boolean

  "method"	? authconfig_method_type

  "pamadditions" ? authconfig_pamadditions_type{}
};

bind "/software/components/authconfig" = component_authconfig_type;

