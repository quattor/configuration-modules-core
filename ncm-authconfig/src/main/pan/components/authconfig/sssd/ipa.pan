# ${license-info}
# ${developer-info}
# ${author-info}

@{
    Contains the data structure describing the SSSD IPA provider
}

declaration template components/authconfig/sssd/ipa;

@{
    Kerberos settings for the IPA access provider
}
type authconfig_sssd_ipa_krb5 = {
    'validate' ? boolean
    'realm' ? string
    'canonicalize' ? boolean
    'use_fast' ? string with match(SELF, '^(never|try|demand)$')
    'confd_path' ? absolute_file_path
};

@{
    dyndns settings for the IPA access provider
}
type authconfig_sssd_ipa_dyndns = {
    'update' ? boolean
    'ttl' ? long(0..)
    'iface' ? valid_interface[]
    'refresh_interval' ? long(0..)
    'update_ptr' ? boolean
    'force_tcp' ? boolean
    'server' ? type_ip
};

@{
    search_base settings for the IPA access provider
}
type authconfig_sssd_ipa_search_base = {
    'hbac' ? string
    'host' ? string
    'selinux' ? string
    'subdomains' ? string
    'master_domain' ? string
    'views' ? string
};


@{
    IPA access provider for SSSD.  See the sssd-ipa man page.
}
type authconfig_sssd_ipa = {
    'krb5' ? authconfig_sssd_ipa_krb5
    'dyndns' ? authconfig_sssd_ipa_dyndns
    'search_base' ? authconfig_sssd_ipa_search_base

    'domain' ? string
    'server' : type_hostname[]
    'backup_server'? type_hostname[]
    'hostname' ? type_hostname
    'enable_dns_sites' ? boolean
    'hbac_refresh' ? long(0..)
    'hbac_selinux' ? long (0..)
    'server_mode' ? boolean
    'automount_location' ? string
};
