object template datastore_cephsys;

include 'components/opennebula/schema';

bind "/metaconfig/contents/datastore/cephsys" = opennebula_datastore;

"/metaconfig/module" = "datastore";

prefix "/metaconfig/contents/datastore/cephsys";
"bridge_list" = list("hyp004.cubone.os");
"ceph_host" = list("ceph001.cubone.os", "ceph002.cubone.os", "ceph003.cubone.os");
"ceph_secret" = "35b161e7-a3bc-440f-b007-cb98ac042646";
"ceph_user" = "libvirt";
"disk_type" = "RBD";
"pool_name" = "one";
"type" = "SYSTEM_DS";
"labels" = list("quattor", "quattor/ceph");
