unique template metaconfig/kerberos/kdc_conf;

include 'metaconfig/kerberos/schema';

bind "/software/components/metaconfig/services/{/var/kerberos/krb5kdc/kdc.conf}/contents" = kdc_conf_file;

prefix "/software/components/metaconfig/services/{/var/kerberos/krb5kdc/kdc.conf}";

"mode" = 0600;
"module" = "kerberos/kdc/config";
"daemons/krb5kdc" = "restart";

"contents/defaults" = nlist();



