declaration template components/${project.artifactId}/v2/schema-mds;

@documentation{ configuration options for a ceph mds daemon }
type ceph_mds_config = {
    'mds_cache_size' ? long = 100000
    'mds_max_purge_files' ? long = 64
    'mds_max_purge_ops' ? long = 8192
    'mds_max_purge_ops_per_pg' ? double = 0.5
};

@documentation{ ceph mds-specific type }
type ceph_mds = {
    include ceph_daemon
    'fqdn' : type_fqdn
    'deploycfg' ? ceph_mds_config
};
