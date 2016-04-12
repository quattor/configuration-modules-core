object template config;

include 'metaconfig/ceph/config';

prefix "/software/components/metaconfig/services/{/etc/sysconfig/ceph}/contents";

'ld_preload'= '/usr/lib64/libjemalloc.so.1';
'ceph_auto_restart_on_upgrade'  = false;

