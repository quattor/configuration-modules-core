declaration template metaconfig/kerberos/schema;

include 'pan/types';

type krb5_logging = {
    "default" : string = "FILE:/var/log/krb5libs.log"
    "kdc" : string = "FILE:/var/log/krb5kdc.log"
    "admin_server" : string = "FILE:/var/log/kadmind.log"
};

type krb5_realm = {
    "kdc" : string
    "admin_server" : string
};

type krb5_libdefaults = {
    "default_realm" : string
    "dns_lookup_realm" : boolean = false
    "dns_lookup_kdc" : boolean = false
    # The lifetimes are specified in seconds
    "ticket_lifetime" : long = 24*60*60
    "renew_lifetime" : long = 7*24*60
    "forwardable" : boolean = true
    "default_keytab_name" : string = "FILE:/etc/krb5.keytab"
};

type krb5_conf_file = {
    "logging" : krb5_logging
    "libdefaults" : krb5_libdefaults
    "realms" : krb5_realm{}
    "domain_realms" : type_fqdn{}
};

type kdc_defaults = {
    "ports" : type_port = 88
    "tcp_ports" : type_port = 884
} = nlist();

type kdc_realm = {
    "acl_file" : string = "/var/kerberos/krb5kdc/kadm5.acl"
    "dict_file" : string = "/usr/share/dict/words"
    "admin_keytab" : string = "/var/kerberos/krb5kdc/krb5kdc/kadm5.keytab"
    "supported_enctypes" : string[] = list("aes256-cts:normal",
                                           "aes128-cts:normal",
                                           "des3-hmac-sha1:normal")
};

type kdc_conf_file = {
    "defaults" : kdc_defaults
    "realms" : kdc_realm{}
};

type kdc_acl_principal = {
    "instance" ? string
    "realm" : string
    "primary" : string
};

type kdc_permissions = string with match(SELF, '^(a|c|d|i|l|m|p|s|x|\*)$');

type kdc_acl = {
    "subject" : kdc_acl_principal
    "permissions" : kdc_permissions[]
    "target" ? kdc_acl_principal
};

type kdc_acl_file = {
    "acls" : kdc_acl[]
};

