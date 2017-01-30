object template krb5_conf;

include 'metaconfig/kerberos/krb5_conf';

prefix "/software/components/metaconfig/services/{/etc/krb5.conf}/contents";

"logging" = dict();
"libdefaults/default_realm" = 'KDC.REALM';
"realms" = dict(
    'KDC.REALM', dict(
        "kdc", 'KDC.SERVER',
        "admin_server", 'KDC.SERVER'
        ));
"domain_realms" = dict('DEFAULT_DOMAIN', 'KDC.REALM');
