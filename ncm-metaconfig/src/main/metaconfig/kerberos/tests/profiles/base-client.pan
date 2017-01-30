unique template base-client;

"/metaconfig/module" = "kerberos/client";

prefix "/metaconfig/contents";
"logging" = dict();
"libdefaults/default_realm" = 'KDC.REALM';
"realms" = dict(
    'KDC.REALM', dict(
        "kdc", 'KDC.SERVER',
        "admin_server", 'KDC.SERVER'
        ));
"domain_realms" = dict('DEFAULT_DOMAIN', 'KDC.REALM');

# verify schema
include 'metaconfig/kerberos/schema';

bind "/metaconfig/contents" = krb5_conf_file;
