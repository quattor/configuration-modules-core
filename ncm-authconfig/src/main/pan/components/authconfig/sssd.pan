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
type sssd_provider_string = string with match(SELF, "^(ldap|simple|local|permit|ipa|ad)$");

@{
    Valid SSSD auth providers.
}
type sssd_auth_provider_string = string with match(SELF, "^(ldap|krb5|local|permit|ipa|ad)$");

@{
    Valid LDAP schema types.
}
type sssd_ldap_schema_string = string with match(SELF, "^(rfc2307|rfc2307bis|ipa|ad)$");

@{
    Simple access provider for SSSD.  See the sssd-simple man page.
}
type authconfig_sssd_simple = {
    "allow_users" ? string[]
    "deny_users" ? string[]
    "allow_groups" ? string[]
    "deny_groups" ? string[]
};


type sssd_service = string with match(SELF, "^(nss|pam|sudo|autofs|ssh|pac)$");

type sssd_global = {
    "debug_level" ? long
    "config_file_version" : long = 2
    "services" : sssd_service[]
    "reconnection_retries" ? long
    "re_expression" ? string
    "full_name_format" ? string
    "try_inotify" ? boolean
    "krb5_rcache_dir" ? string
    "default_domain_suffix" ? string
};

type sssd_pam = {
    "debug_level" ? long
    "reconnection_retries" ? long
    "offline_credentials_expiration" ? long
    "offline_failed_login_attempts" ? long
    "offline_failed_login_delay" ? long
    "pam_verbosity" ? long
    "pam_id_timeout" ? long
    "pam_pwd_expiration_warning" ? long
    "get_domains_timeout" ? long
};

type sssd_nss = {
    "debug_level" ? long
    "reconnection_retries" ? long
    "enum_cache_timeout" ? long
    "entry_cache_nowait_percentage" ? long
    "entry_negative_timeout" ? long
    "filter_users" ? string
    "filter_users_in_groups" ? boolean
    "filter_groups" ? string
    "memcache_timeout" ? long
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

type authconfig_sssd_domain  = {
    "reconnection_retries" ? long
    "ldap" ? authconfig_sssd_ldap
    "ipa" ? authconfig_sssd_ipa
    "simple" ? authconfig_sssd_simple
    "local" ? authconfig_sssd_local
    "access_provider" ? sssd_provider_string
    "id_provider" ? sssd_provider_string
    "auth_provider" ? sssd_auth_provider_string
    "chpass_provider" ? sssd_auth_provider_string
    "debug_level" ? long
    "sudo_provider" ? string
    "selinux_provider" ? string
    "subdomains_provider" ? string
    "autofs_provider" ? string
    "hostid_provider" ? string
    "re_expression" ? string
    "full_name_format" : string = "%1$s@%2$s"
    "lookup_family_order" : string = "ipv4_first"
    "dns_resolver_timeout" : long = 5
    "dns_discovery_domain" ? string
    "override_gid" ? long
    "case_sensitive" : boolean = true
    "proxy_fast_alias" ? boolean
    "subdomain_homedir" ? string
    "proxy_pam_target" ? string
    "proxy_lib_name" ? string
    "min_id" : long = 1
    "max_id" : long = 0
    "enumerate" : boolean = false
    "timeout" : long = 10
    "force_timeout" ? long with {
        deprecated(0,
            "Warning: sssd/force_timeout was removed from sssd 1.14.2 and will be removed in a future Quattor release."
        );
        true;
    }
    "entry_cache_timeout" : long = 5400
    "entry_cache_user_timeout" ? long
    "entry_cache_group_timeout" ? long
    "entry_cache_netgroup_timeout" ? long
    "entry_cache_service_timeout" ? long
    "entry_cache_sudo_timeout" ? long
    "entry_cache_autofs_timeout" ? long
    "refresh_expired_interval" ? long
    "cache_credentials" : boolean = false
    "account_cache_expiration" : long = 0
    "pwd_expiration_warning" ? long
    "ldap_schema" ? sssd_ldap_schema_string
    "ldap_group_name" ? string
    "ldap_referrals" ? boolean
    "ldap_sasl_mech" ? string
    "ldap_sasl_authid" ? string
    "ldap_id_mapping" ? boolean
    "ldap_search_base" ? string
    "ldap_account_expire_policy" ? string
    "ldap_access_order" ? string
    "ldap_krb5_keytab" ? string
    "krb5_realm" ? string
    "krb5_use_enterprise_principal" ? boolean
    "krb5_use_kdcinfo" ? boolean
    "ad_enable_gc" ? boolean
    "ad_domain" ? string
    "ad_enabled_domains" ? string
    "ad_gpo_access_control" ? string
};

type authconfig_method_sssd_type = {
    include authconfig_method_generic_type
    "nssonly" : boolean = false
    "domains" : authconfig_sssd_domain{}
    "global" : sssd_global
    "pam" : sssd_pam
    "nss" : sssd_nss
};
