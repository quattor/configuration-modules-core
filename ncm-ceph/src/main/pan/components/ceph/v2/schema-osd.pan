declaration template components/${project.artifactId}/v2/schema-osd;

@documentation{ configuration options for a ceph osd daemon }
type ceph_osd_config = {
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
    'osd_deep_scrub_large_omap_object_key_threshold' ? long(0..)
    'osd_op_queue' ? choice('wpq', 'prioritized', 'debug_random') = 'wpq'
    'osd_op_queue_cut_off' ? choice('low', 'high', 'debug_random') = 'low'
};

@documentation{
ceph osd-specific type
Only bluestore support for now
dmcrypt supported with ceph-volume > 12.2.3
}
type ceph_osd = {
    include ceph_daemon
    'class' ? string
    'storetype' : choice('bluestore') = 'bluestore'
    'dmcrypt' ? boolean
};
