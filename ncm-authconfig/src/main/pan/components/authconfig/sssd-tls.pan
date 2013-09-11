# ${license-info}
# ${developer-info}
# ${author-info}

@{

    Contains the data structure describing the TLS configurations in
    the LDAP SSSD provider.

    Fields in these data types match the ldap_tls_* fields in the
    sssd-ldap man page.
}

declaration template components/authconfig/sssd-tls;

type ldap_req_checks = string with match(SELF, "^(never|allow|try|demand|hard)$") ||
    error ("LDAP certificate requests must be valid acording to ssd-ldap: " + SELF);


type sssd_tls = {
    "cacert" ?  string
    "cacertdir" ?  string
    "cert" :  string
    "key" :  string
    "cipher_suite" :  string[]
    "reqcert" : ldap_req_checks = "hard"
} with exists(SELF["cacert"]) || exists(SELF["cacertdir"]) ||
    error("LDAP TLS requires at least one of cacert or cacertdir");
