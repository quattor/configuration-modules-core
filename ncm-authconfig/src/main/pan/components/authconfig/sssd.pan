# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/authconfig/sssd;

include 'components/authconfig/sssd/user';
include 'components/authconfig/sssd/sudo';
include 'components/authconfig/sssd/sasl';
include 'components/authconfig/sssd/tls';
include 'components/authconfig/sssd/ldap';
include 'components/authconfig/sssd/ipa';

@{
    Valid SSSD providers.
}
type sssd_provider_string = choice('ldap', 'simple', 'local', 'permit', 'ipa', 'ad');

@{
    Valid SSSD auth providers.
}
type sssd_auth_provider_string = choice('ldap', 'krb5', 'local', 'permit', 'ipa', 'ad');

@{
    Valid LDAP schema types.
}
type sssd_ldap_schema_string = choice('rfc2307', 'rfc2307bis', 'ipa', 'ad');

@{ Valid debug levels, either 0-10 or a bitmask from 0x0010-0xFFF0 (i.e. levels 11-15 are invalid )}
type sssd_debug_level = long(0..0xFFF0) with {
    result = false;

    if (SELF >= 0 && SELF <= 10) {
        deprecated(0, 'Old format debug levels (0-10) are deprecated from sssd 1.7.0');
        result = true;
    } else if (SELF >= 0x0010 && SELF <= 0xFFF0) {
        result = true;
    };

    result;
};

@{
    Simple access provider for SSSD.  See the sssd-simple man page.
}
type authconfig_sssd_simple = {
    "allow_users" ? string_trimmed[]
    "deny_users" ? string_trimmed[]
    "allow_groups" ? string_trimmed[]
    "deny_groups" ? string_trimmed[]
};


type sssd_service = choice('nss', 'pam', 'sudo', 'autofs', 'ssh', 'pac');

type sssd_global = {
    "debug_level" ? sssd_debug_level
    "config_file_version" : long = 2
    "services" : sssd_service[]
    "reconnection_retries" ? long(0..)
    "re_expression" ? string_trimmed
    "full_name_format" ? string_trimmed
    "try_inotify" ? boolean
    "krb5_rcache_dir" ? string_trimmed
    "default_domain_suffix" ? string_trimmed
};

type sssd_pam = {
    "debug_level" ? sssd_debug_level
    "reconnection_retries" ? long(0..)
    "offline_credentials_expiration" ? long(0..)
    "offline_failed_login_attempts" ? long(0..)
    "offline_failed_login_delay" ? long(0..)
    "pam_verbosity" ? long(0..3)
    "pam_id_timeout" ? long(1..)
    "pam_pwd_expiration_warning" ? long(0..)
    "get_domains_timeout" ? long(1..)
};

type sssd_nss = {
    "debug_level" ? sssd_debug_level
    "reconnection_retries" ? long(0..)
    "enum_cache_timeout" ? long(0..)
    "entry_cache_nowait_percentage" ? long(0..99)
    "entry_negative_timeout" ? long(0..)
    "filter_users" ? string_trimmed
    "filter_users_in_groups" ? boolean
    "filter_groups" ? string_trimmed
    "memcache_timeout" ? long(0..)
    "override_shell" ? absolute_file_path
};

type authconfig_sssd_local = {
    "default_shell" : absolute_file_path = "/bin/bash"
    "base_directory" : absolute_file_path = "/home"
    "create_homedir" : boolean = true
    "remove_homedir" : boolean = true
    "homedir_umask" : type_octal_mode = 077
    "skel_dir" : absolute_file_path = "/etc/skel"
    "mail_dir" : absolute_file_path = "/var/mail"
    "userdel_cmd" ? absolute_file_path
};

type authconfig_sssd_domain  = {
    "reconnection_retries" ? long(0..)
    "ldap" ? authconfig_sssd_ldap
    "ipa" ? authconfig_sssd_ipa
    "simple" ? authconfig_sssd_simple
    "local" ? authconfig_sssd_local
    "access_provider" ? sssd_provider_string
    "id_provider" ? sssd_provider_string
    "auth_provider" ? sssd_auth_provider_string
    "chpass_provider" ? sssd_auth_provider_string
    "debug_level" ? sssd_debug_level
    "sudo_provider" ? string_trimmed
    "selinux_provider" ? string_trimmed
    "subdomains_provider" ? string_trimmed
    "autofs_provider" ? string_trimmed
    "hostid_provider" ? string_trimmed
    "re_expression" ? string_trimmed
    "full_name_format" : string_trimmed = "%1$s@%2$s"
    "lookup_family_order" : string_trimmed = "ipv4_first"
    "dns_resolver_timeout" : long(1..) = 5
    "dns_discovery_domain" ? string_trimmed
    "override_gid" ? long(0..)
    "override_shell" ? absolute_file_path
    "case_sensitive" : boolean = true
    "proxy_fast_alias" ? boolean
    "subdomain_homedir" ? string_trimmed
    "proxy_pam_target" ? string_trimmed
    "proxy_lib_name" ? string_trimmed
    "min_id" : long(0..) = 1
    "max_id" : long(0..) = 0
    "enumerate" : boolean = false
    "timeout" : long(1..) = 10
    "force_timeout" ? long(1..) with {
        deprecated(0,
            "Warning: sssd/force_timeout was removed from sssd 1.14.2 and will be removed in a future Quattor release."
        );
        true;
    }
    "entry_cache_timeout" : long(1..) = 5400
    "entry_cache_user_timeout" ? long(1..)
    "entry_cache_group_timeout" ? long(1..)
    "entry_cache_netgroup_timeout" ? long(1..)
    "entry_cache_service_timeout" ? long(1..)
    "entry_cache_sudo_timeout" ? long(1..)
    "entry_cache_autofs_timeout" ? long(1..)
    "refresh_expired_interval" ? long(1..)
    "cache_credentials" : boolean = false
    "account_cache_expiration" : long(0..) = 0
    "pwd_expiration_warning" ? long(0..)
    "ldap_schema" ? sssd_ldap_schema_string
    "ldap_group_name" ? string_trimmed
    "ldap_referrals" ? boolean
    "ldap_sasl_mech" ? choice('gssapi')
    "ldap_sasl_authid" ? string_trimmed
    "ldap_id_mapping" ? boolean
    "ldap_search_base" ? string_trimmed
    "ldap_account_expire_policy" ? string_trimmed
    "ldap_access_order" ? string_trimmed
    "ldap_krb5_keytab" ? string_trimmed
    "krb5_realm" ? type_fqdn
    "krb5_use_enterprise_principal" ? boolean
    "krb5_use_kdcinfo" ? boolean
    "ad_enable_gc" ? boolean
    "ad_domain" ? string_trimmed
    "ad_enabled_domains" ? string_trimmed
    "ad_gpo_access_control" ? string_trimmed
};

type authconfig_method_sssd_type = {
    include authconfig_method_generic_type
    "nssonly" : boolean = false
    "domains" : authconfig_sssd_domain{}
    "global" : sssd_global
    "pam" : sssd_pam
    "nss" : sssd_nss
};
