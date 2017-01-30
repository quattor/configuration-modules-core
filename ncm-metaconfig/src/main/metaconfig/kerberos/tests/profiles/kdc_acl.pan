object template kdc_acl;

include 'metaconfig/kerberos/kdc_acl';

prefix "/software/components/metaconfig/services/{/var/kerberos/krb5kdc/kadm5.acl}/contents";
"acls/0/subject" = dict(
    "realm", 'MYREALM',
    "primary", "*",
    "instance", "admin",
);
"acls/0/permissions" = list("*");
