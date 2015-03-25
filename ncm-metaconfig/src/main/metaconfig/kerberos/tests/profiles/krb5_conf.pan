object template krb5_conf;

include 'metaconfig/kerberos/krb5_conf';

prefix "/software/components/metaconfig/services/{/etc/krb5.conf}/contents";

"logging" = nlist();
"libdefaults/default_realm" = 'KDC.REALM';
"realms" = nlist(
    'KDC.REALM', nlist(
        "kdc", 'KDC.SERVER',
        "admin_server", 'KDC.SERVER'
        ));
"domain_realms" = nlist('DEFAULT_DOMAIN', 'KDC.REALM');
