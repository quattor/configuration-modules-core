declaration template components/${project.artifactId}/v2/schema-mon;

@documentation{ configuration options for a ceph monitor daemon }
type ceph_mon_config = {
};

@documentation{ ceph monitor-specific type }
type ceph_monitor = {
    include ceph_daemon
    'fqdn' : type_fqdn
};

