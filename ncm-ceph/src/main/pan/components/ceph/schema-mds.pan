declaration template components/${project.artifactId}/schema-mds;

@documentation{ configuration options for a ceph mds daemon }
type ceph_mds_config = { 
    include ceph_daemon_config
    'mds_cache_size' ? long = 100000
};

@documentation{ ceph mds-specific type }
type ceph_mds = { 
     include ceph_daemon
    'fqdn'  : type_fqdn
    'config' ? ceph_mds_config
};

