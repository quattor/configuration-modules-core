object template datastore_shar;

include 'components/opennebula/schema';

bind "/metaconfig/contents/datastore" = opennebula_datastore;

"/metaconfig/module" = "datastore";

prefix "/metaconfig/contents/datastore";
"name" = "nfs";
"datastore_capacity_check" = true;
"type" = "IMAGE_DS";
"ds_mad" = "fs";
"tm_mad" = "shared";
