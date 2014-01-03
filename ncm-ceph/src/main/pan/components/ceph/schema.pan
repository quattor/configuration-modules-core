# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

@{ type for a generic ceph daemon @}
type ceph_daemon = {
    'name'  : string
    'up'    ? boolean = true
};

@{ ceph monitor-specific type @}
type ceph_monitor = {
    include ceph_daemon
};

@{ ceph osd-specific type @}
type ceph_osd = {
    include ceph_daemon
    'id'            : long
    'host'          : string
    'in'            ? boolean = true
    'osd_path'      : string
    'journal_path'  ? string
};

@{ ceph msd-specific type @}
type ceph_msd = {
     include ceph_daemon
};

@{ ceph cluster-wide config parameters @}
type ceph_cluster_config = {
    'fsid'                      : string
    'filestore_xattr_use_omap'  ? boolean = true
    'osd_journal_size'          ? long(0..) = 10240
    'mon_initial_members'       : string [1..]
    'auth_supported'            ? string = 'cephx'
};

@{ overarching ceph cluster type, with osds, mons and msds @}
type ceph_cluster = {
    'config'                    : ceph_cluster_config
    'osds'                      : ceph_osd {}
    'monitors'                  : ceph_monitor {1..}
    'msds'                      ? ceph_msd {}
    'deployhosts'               : type_fqdn {1..}
};

@{ ceph clusters @}
type ${project.artifactId}_component = {
    include structure_component
    'clusters'  : ceph_cluster {}
};

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
