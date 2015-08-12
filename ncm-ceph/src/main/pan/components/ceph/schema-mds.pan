declaration template components/${project.artifactId}/schema-mds;

@documentation{ ceph mds config }
type ceph_mds_config = { 
    include ceph_daemon_config
};

@documentation{ ceph mds-specific type }
type ceph_mds = { 
     include ceph_daemon
    'fqdn'  : type_fqdn
    'config' ? ceph_mds_config
};

