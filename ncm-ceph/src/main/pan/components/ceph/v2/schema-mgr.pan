declaration template components/${project.artifactId}/v2/schema-mgr;

@documentation{ configuration options for a ceph mgr module like dashboard,prometheus,.. }
type ceph_mgr_module = string{};

@documentation{ configuration options for a ceph mgr daemon }
type ceph_mgr_config = {
    'modules' ? ceph_mgr_module{}
};

