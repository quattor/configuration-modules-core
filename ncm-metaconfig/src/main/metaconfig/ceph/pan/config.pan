unique template metaconfig/ceph/config;

include 'metaconfig/ceph/schema';

bind "/software/components/metaconfig/services/{/etc/sysconfig/ceph}/contents" = ceph_sysconfig;

prefix "/software/components/metaconfig/services/{/etc/sysconfig/ceph}";
"module" = "ceph/sysconfig";
