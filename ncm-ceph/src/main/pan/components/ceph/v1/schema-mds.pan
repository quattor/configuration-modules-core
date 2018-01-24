declaration template components/${project.artifactId}/v1/schema-mds;

@documentation{ configuration options for a ceph mds daemon }
type ceph_mds_config = {
    include ceph_daemon_config
    'mds_cache_size' ? long = 100000
    'mds_max_purge_files' ? long = 64
    'mds_max_purge_ops' ? long = 8192
    'mds_max_purge_ops_per_pg' ? double = 0.5
    'mds_log_max_expiring' ? long = 20
    'mds_log_max_segments' ? long = 30
};

@documentation{ ceph mds-specific type }
type ceph_mds = {
    include ceph_daemon
    'fqdn' : type_fqdn
    'config' ? ceph_mds_config
};
