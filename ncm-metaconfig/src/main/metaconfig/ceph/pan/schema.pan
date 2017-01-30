declaration template metaconfig/ceph/schema;

include 'pan/types';

@{ type for configuring the ceph sysconfig file }
type ceph_sysconfig = {
    'ld_preload' ? string
    'ceph_auto_restart_on_upgrade' : boolean = false
};

