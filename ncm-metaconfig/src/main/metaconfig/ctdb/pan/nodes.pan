unique template metaconfig/ctdb/nodes;

include 'metaconfig/ctdb/schema';

bind "/software/components/metaconfig/services/{/etc/ctdb/nodes}/contents/nodelist" = ctdb_nodes;

prefix "/software/components/metaconfig/services/{/etc/ctdb/nodes}";
"daemons/ctdb" = "restart";
"module" = "ctdb/list";
