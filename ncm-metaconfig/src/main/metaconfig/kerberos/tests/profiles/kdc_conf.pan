object template kdc_conf;

include 'metaconfig/kerberos/kdc_conf';

prefix "/software/components/metaconfig/services/{/var/kerberos/krb5kdc/kdc.conf}/contents";
"realms" = dict('MYREALM', dict());
