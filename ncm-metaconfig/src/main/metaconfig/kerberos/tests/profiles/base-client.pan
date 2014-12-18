unique template base-client;

"/metaconfig/module" = "kerberos/client";

prefix "/metaconfig/contents";
"logging" = nlist();
"libdefaults/default_realm" = 'KDC.REALM';
"realms" = nlist(
    'KDC.REALM', nlist(
        "kdc", 'KDC.SERVER',
        "admin_server", 'KDC.SERVER'
        ));
"domain_realms" = nlist('DEFAULT_DOMAIN', 'KDC.REALM');

# verify schema
include 'metaconfig/kerberos/schema';

bind "/metaconfig/contents" = krb5_conf_file;
