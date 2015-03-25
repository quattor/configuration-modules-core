unique template metaconfig/kerberos/kdc_acl;

include 'metaconfig/kerberos/schema';

bind "/software/components/metaconfig/services/{/var/kerberos/krb5kdc/kadm5.acl}/contents" = kdc_acl_file;

prefix "/software/components/metaconfig/services/{/var/kerberos/krb5kdc/kadm5.acl}";
"mode" = 0600;
"module" = "kerberos/kdc/acl";
