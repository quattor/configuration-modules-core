declaration template components/${project.artifactId}/schema-osd;

type ceph_osd_config = {
    include ceph_daemon_config
    'osd_journal_size'  ? long(0..) 
    'osd_objectstore'   ? string
};

@documentation{ 
ceph osd-specific type 
The key of the ceph_osd should be the path to the mounted disk. 
This can be an absolute path or a relative one to /var/lib/ceph/osd/
journal_path should be the path to a journal file
This can be an absolute path or a relative one to /var/lib/ceph/log/
With labels osds can be grouped. This should also be defined in root. 
}
type ceph_osd = { 
    include ceph_daemon
    'config'        ? ceph_osd_config
    'in'            ? boolean = true
    'journal_path'  ? string
    'crush_weight'  : double(0..) = 1.0 
    'labels'        ? string[1..]
};

@documentation{ ceph osdhost-specific type }
type ceph_osd_host = { 
    'fqdn'          : type_fqdn
    'osds'          : ceph_osd {}
};

