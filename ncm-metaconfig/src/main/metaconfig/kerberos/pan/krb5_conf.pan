unique template metaconfig/kerberos/krb5_conf;

include 'metaconfig/kerberos/schema';

"/software/components/metaconfig/services/{/etc/krb5.conf}/module" = "kerberos/client";

bind "/software/components/metaconfig/services/{/etc/krb5.conf}/contents" = krb5_conf_file;
