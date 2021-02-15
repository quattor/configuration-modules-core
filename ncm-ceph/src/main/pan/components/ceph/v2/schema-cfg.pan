# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/${project.artifactId}/v2/schema-cfg;


@documentation{
ceph minimal config parameters
with centralised config db this should be the only thing in ceph.conf
generate an fsid with uuidgen
 }
type ceph_minimal_config_global = {
    'fsid' : type_uuid
    'mon_host' : type_fqdn[1..]
    'mon_initial_members' ? type_shorthostname[1..]
    'public_network' ? type_network_name
    'cluster_network' ? type_network_name
};

type ceph_minimal_config = {
    'global' : ceph_minimal_config_global
};

@documentation{
ceph cluster-wide config parameters
 }
type ceph_global_config = {
    'auth_client_required' : choice('cephx', 'none') = 'cephx'
    'auth_cluster_required' : choice('cephx', 'none') = 'cephx'
    'auth_service_required' : choice('cephx', 'none') = 'cephx'
    'mon_cluster_log_to_syslog' : boolean = true
    'mon_max_pg_per_osd' ? long
    'mon_osd_down_out_subtree_limit' ? string = 'rack'
    'mon_osd_min_down_reporters' ? long(0..)
    'mon_osd_min_down_reports' ? long(0..)
    'mon_osd_warn_op_age' ? long = 32
    'mon_osd_err_op_age_ratio' ? long = 128
    'ms_type' ? choice('simple', 'async', 'xio')
    'op_queue' ? choice('prio', 'wpq')
    'osd_journal_size' ? long(0..)
    'osd_max_pg_per_osd_hard_ratio' ? long
    'osd_pool_default_min_size' ? long(0..)
    'osd_pool_default_pg_num' ? long(0..)
    'osd_pool_default_pgp_num' ? long(0..)
    'osd_pool_default_size' ? long(0..)
};

type ceph_global_config_file = {
    include ceph_minimal_config_global
    include ceph_global_config
};

type ceph_configfile = {
    'global' : ceph_global_config_file
    'mds' ? ceph_mds_config
    'osd' ? ceph_osd_config
    'mon' ? ceph_mon_config
    'rgw' ? ceph_rgw_config{}
};

@documentation{
config to be put in the ceph config centralised db'
 }
type ceph_configdb = {
    'global' : ceph_global_config
    'mds' ? ceph_mds_config
    'osd' ? ceph_osd_config
    'mon' ? ceph_mon_config
    'mgr' ? ceph_mgr_config
    'rgw' ? ceph_rgw_config{}
};


