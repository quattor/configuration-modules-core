# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

type ceph_daemon = {
    'id'    : long
    'name'  : string
    'up'    ? boolean = true
};
type ceph_monitor = {
    include ceph_daemon
    'addr'  : string
};
type ceph_osd = {
    include ceph_daemon
    'uuid'          : string
    'in'            ? boolean = true
    'osd_path'      : string
    'journal_path'  ? string
};
type ceph_osdhost = {
    'hostname' : type_fqdn
    'osds' : ceph_osd {}
};
type ceph_msd = {
     include ceph_daemon
};
type ceph_cluster_config = {
    'fsid'                      : string
    'filestore_xattr_use_omap'  ? boolean = true
    'osd_journal_size'          ? long(0..) = 10240
    'mon_initial_members'       : string [1..]
    'auth_supported'            ? string = 'cephx'

};
type ceph_cluster = {
    'config'                    : ceph_cluster_config
    'osdhosts'                  : ceph_osdhost {}
    'monitors'                  : ceph_monitor {1..}
    'msds'                      ? ceph_msd {}
};
type ${project.artifactId}_component = {
    include structure_component
    'clusters'  : ceph_cluster {}
};

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
