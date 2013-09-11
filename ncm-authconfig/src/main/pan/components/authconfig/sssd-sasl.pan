# ${license-info}
# ${developer-info}
# ${author-info}

@{

    Contains the data structure describing the SASL and KRB5
    configurations in the LDAP SSSD provider.

    Fields in these data types match the ldap_sasl_* and ldap_krb5_*
    fields in the sssd-ldap man page.

}

declaration template components/authconfig/sssd-sasl;

type sssd_sasl = {
    "mech" ? string
    "authid" ? string
    "realm" ? string
    "canonicalize" ? boolean
    "minssf" ?  long
};

type sssd_krb5 = {
    "keytab" ? string
    "init_creds" ? boolean
    "ticket_lifetime" ?  long
};
