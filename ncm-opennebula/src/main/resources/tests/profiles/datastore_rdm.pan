object template datastore_rdm;

include 'components/opennebula/schema';

bind "/metaconfig/contents/datastore/rdm" = opennebula_datastore;

"/metaconfig/module" = "datastore";

prefix "/metaconfig/contents/datastore/rdm";
"datastore_capacity_check" = false;
"disk_type" = "BLOCK";
"tm_mad" = "dev";
"ds_mad" = "dev";
"type" = "IMAGE_DS";
"labels" = list("quattor", "quattor/rdm");
