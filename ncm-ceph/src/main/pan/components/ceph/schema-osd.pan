declaration template components/${project.artifactId}/schema-osd;

@documentation{ configuration options for a ceph osd daemon }
type ceph_osd_config = {
    include ceph_daemon_config
    'osd_deep_scrub_interval' ? double(0..)
    'osd_journal_size' ? long(0..)
    'osd_max_scrubs' ? long(0..)
    'osd_objectstore' ? string
    'osd_op_threads' ? long(0..)
    'osd_scrub_begin_hour' ? long(0..24)
    'osd_scrub_end_hour' ? long(0..24)
    'osd_scrub_load_threshold' ? double(0..)
    'osd_scrub_min_interval' ? double(0..)
    'osd_scrub_max_interval' ? double(0..)
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
    'config' ? ceph_osd_config
    'in' ? boolean = true
    'journal_path' ? string
    'crush_weight' : double(0..) = 1.0
    'labels' ? string[1..]
};

@documentation{ ceph osdhost-specific type, defining all osds on a host }
type ceph_osd_host = {
    'fqdn' : type_fqdn
    'osds' : ceph_osd {}
};

