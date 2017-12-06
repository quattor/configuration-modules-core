object template datastore_shar;

include 'components/opennebula/schema';

bind "/metaconfig/contents/datastore/nfs" = opennebula_datastore;

"/metaconfig/module" = "datastore";

prefix "/metaconfig/contents/datastore/nfs";
"datastore_capacity_check" = true;
"type" = "IMAGE_DS";
"ds_mad" = "fs";
"tm_mad" = "shared";
"labels" = list("quattor", "quattor/nfs");
"permissions/owner" = "lsimngar";
"permissions/group" = "users";
"permissions/mode" = 0440;

