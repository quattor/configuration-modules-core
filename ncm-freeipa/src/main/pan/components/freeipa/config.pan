${componentconfig}

variable FREEIPA_CLI_REQUIRES_PAM_KRB5 ?= true;

'cli_packages' ?= {
    t = list(
        'ncm-freeipa',
        'nss-pam-ldapd',
        'ipa-client',
        'nss-tools',
        'openssl',
    );
    if (FREEIPA_CLI_REQUIRES_PAM_KRB5) {
        append(t, 'pam_krb5');
    };
    t;
};
