unique template metaconfig/ctdb/public_addresses;

include 'metaconfig/ctdb/schema';

bind "/software/components/metaconfig/services/{/etc/ctdb/public_addresses}/contents/addresses" = ctdb_public_addresses;

prefix "/software/components/metaconfig/services/{/etc/ctdb/public_addresses}";
"daemons/ctdb" = "restart";
"module" = "ctdb/publicaddress";
