object template remoteconf_ceph;

include 'components/opennebula/schema';

bind "/metaconfig/contents/remoteconf_ceph" = opennebula_remoteconf_ceph;

"/metaconfig/module" = "remoteconf_ceph";

prefix "/metaconfig/contents/remoteconf_ceph";
"pool_name" = "one";
"host" = "hyp004.cubone.os";
"ceph_user" = "libvirt";
"staging_dir" = "/var/tmp";
"rbd_format" = 2;
