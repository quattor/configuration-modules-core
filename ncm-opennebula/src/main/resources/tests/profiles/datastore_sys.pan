object template datastore_sys;

include 'components/opennebula/schema';

bind "/metaconfig/contents/datastore/system" = opennebula_datastore;

"/metaconfig/module" = "datastore";

prefix "/metaconfig/contents/datastore/system";
"tm_mad" = "shared";
"ds_mad" = "fs";
"type" = "SYSTEM_DS";
"clusters" = list("default", "red.cluster");
