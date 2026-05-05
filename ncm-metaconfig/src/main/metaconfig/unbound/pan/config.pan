unique template metaconfig/unbound/config;

include 'metaconfig/unbound/schema';

bind "/software/components/metaconfig/services/{/etc/unbound/unbound.conf}/contents" = structure_unbound;

prefix  "/software/components/metaconfig/services/{/etc/unbound/unbound.conf}";
"mode" = 0640;
"owner" = "root";
"group" = "root";
"module" = "unbound/unbound";
"daemons/unbound" = "restart";

