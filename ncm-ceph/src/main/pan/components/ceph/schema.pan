# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

@{ type for a generic ceph daemon @}
type ceph_daemon = {
    'up'    : boolean = true
};

@{ ceph monitor-specific type @}
type ceph_monitor = {
    include ceph_daemon
    'fqdn'  : type_fqdn
};


@{ ceph osd-specific type @}
type ceph_osd = {
    include ceph_daemon
    'in'            ? boolean = true
    'journal_path'  ? string
};

@{ ceph osd-specific type @}
type ceph_osd_host = {
    'fqdn'          : type_fqdn
    'osds'          : ceph_osd {}
};

@{ ceph mds-specific type @}
type ceph_mds = {
     include ceph_daemon
    'fqdn'  : type_fqdn
};

@{ ceph cluster-wide config parameters @}
type ceph_cluster_config = {
    'fsid'                      : string
    'filestore_xattr_use_omap'  : boolean = true
    'osd_journal_size'          : long(0..) = 10240
    'mon_initial_members'       : string [1..]
    'public_network'            : string #TODO: check/write type for this
    'auth_service_required'     : string = 'cephx'
    'auth_client_required'      : string = 'cephx'
    'auth_cluster_required'     : string = 'cephx'
    'osd_pool_default_pg_num'   : long(0..) = 600
    'osd_pool_default_pgp_num'  : long(0..) = 600
    'osd_pool_default_size'     : long(0..) = 2
    'osd_pool_default_min_size' : long(0..) = 1

};

@{ overarching ceph cluster type, with osds, mons and msds @}
type ceph_cluster = {
    'config'                    : ceph_cluster_config
    'osdhosts'                  : ceph_osd_host {}
    'monitors'                  : ceph_monitor {1..}
    'mdss'                      ? ceph_mds {}
    'deployhosts'               : type_fqdn {1..}
};

@{ ceph clusters @}
type ${project.artifactId}_component = {
    include structure_component
    'clusters'         : ceph_cluster {}
    'ceph_version'     ? string 
    'deploy_version'   ? string 

};

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
