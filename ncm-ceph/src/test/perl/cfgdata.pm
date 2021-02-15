package cfgdata;

use strict;
use warnings;

use Readonly;

Readonly our $MINCFG_OUT => <<EOD;
[global]
fsid=8c09a56c-5859-4bc0-8584-d2c2232d62f6
mon_host=host1.aaa.be,host2.aaa.be,host3.aaa.be
EOD

Readonly our $CFGFILE_OUT => <<EOD;
[client.rgw.test]
host=host3
keyring=keyfile
log_file=/var/log/radosgw/client.radosgw.gateway.log
rgw_dns_name=host3.aaa.be
rgw_enable_ops_log=1
rgw_enable_usage_log=1
rgw_frontends="civetweb port=8000"
rgw_print_continue=0
rgw_socket_path=

[global]
auth_client_required=cephx
auth_cluster_required=cephx
auth_service_required=cephx
fsid=8c09a56c-5859-4bc0-8584-d2c2232d62f6
mon_cluster_log_to_syslog=1
mon_host=host1.aaa.be,host2.aaa.be,host3.aaa.be
mon_initial_members=host1,host2,host3
public_network=192.168.0.0/20

[osd]
osd_max_scrubs=4
EOD

Readonly our $CONFJSON => '[{"section":"global","name":"auth_client_required","value":"cephx","level":"advanced","can_update_at_runtime":false,"mask":""},{"section":"global","name":"auth_cluster_required","value":"cephx","level":"advanced","can_update_at_runtime":false,"mask":""},{"section":"mgr","name":"mgr/dashboard/server_port","value":"7000","level":"unknown","can_update_at_runtime":false,"mask":""},{"section":"global","name":"auth_service_required","value":"cephx","level":"advanced","can_update_at_runtime":false,"mask":""},{"section":"global","name":"bluestore_warn_on_legacy_statfs","value":"false","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"global","name":"mon_cluster_log_to_syslog","value":"1","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"global","name":"mon_max_pg_per_osd","value":"500","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"global","name":"mon_osd_down_out_subtree_limit","value":"host","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"global","name":"mon_osd_warn_op_age","value":"64.000000","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"global","name":"osd_journal_size","value":"10240","level":"advanced","can_update_at_runtime":false,"mask":""},{"section":"global","name":"osd_pool_default_min_size","value":"2","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"global","name":"osd_pool_default_pg_num","value":"512","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"global","name":"osd_pool_default_pgp_num","value":"512","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"global","name":"osd_pool_default_size","value":"3","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"mon","name":"mon_allow_pool_delete","value":"false","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"osd","name":"osd_deep_scrub_large_omap_object_key_threshold","value":"900000","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"osd","name":"osd_max_markdown_count","value":"10","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"osd","name":"osd_op_queue","value":"wpq","level":"advanced","can_update_at_runtime":false,"mask":""},{"section":"osd","name":"osd_op_queue_cut_off","value":"high","level":"advanced","can_update_at_runtime":false,"mask":""},{"section":"mds","name":"mds_cache_memory_limit","value":"21474836480","level":"basic","can_update_at_runtime":true,"mask":""},{"section":"mds","name":"mds_log_max_segments","value":"200","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"mds","name":"mds_max_purge_files","value":"2560","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"mds","name":"mds_max_purge_ops","value":"327600","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"mds","name":"mds_max_purge_ops_per_pg","value":"20.000000","level":"advanced","can_update_at_runtime":true,"mask":""},{"section":"mds","name":"osd_op_queue_cut_off","value":"high","level":"advanced","can_update_at_runtime":false,"mask":""}]';

Readonly our %CONF_HASH => (
  'global' => {
    'auth_client_required' => 'cephx',
    'auth_cluster_required' => 'cephx',
    'auth_service_required' => 'cephx',
    'bluestore_warn_on_legacy_statfs' => 'false',
    'mon_cluster_log_to_syslog' => '1',
    'mon_max_pg_per_osd' => '500',
    'mon_osd_down_out_subtree_limit' => 'host',
    'mon_osd_warn_op_age' => '64.000000',
    'osd_journal_size' => '10240',
    'osd_pool_default_min_size' => '2',
    'osd_pool_default_pg_num' => '512',
    'osd_pool_default_pgp_num' => '512',
    'osd_pool_default_size' => '3'
  },
  'mds' => {
    'mds_cache_memory_limit' => '21474836480',
    'mds_log_max_segments' => '200',
    'mds_max_purge_files' => '2560',
    'mds_max_purge_ops' => '327600',
    'mds_max_purge_ops_per_pg' => '20.000000',
    'osd_op_queue_cut_off' => 'high'
  },
  'mon' => {
    'mon_allow_pool_delete' => 'false'
  },
  'mgr' => {
    'mgr/dashboard/server_port' => '7000'
  },
  'osd' => {
    'osd_deep_scrub_large_omap_object_key_threshold' => '900000',
    'osd_max_markdown_count' => '10',
    'osd_op_queue' => 'wpq',
    'osd_op_queue_cut_off' => 'high'
  }
);

Readonly our %PROFILE_CFG => (
  'global' => {
    'auth_client_required' => 'cephx',
    'auth_cluster_required' => 'cephx',
    'auth_service_required' => 'cephx',
    'mon_cluster_log_to_syslog' => 1,
    'op_queue' => 'wpq',
    'mon_osd_down_out_subtree_limit' => 'rack'
  },
  'mds' => {
    'mds_max_purge_ops_per_pg' => '10'
  },
  'mgr' => {
    'mgr/dashboard/server_addr' => 'localhost',
    'mgr/dashboard/server_port' => '7000',
    'mgr/telemetry/contact' => 'me'
  }
);

Readonly our %DEPLOY_CFG => (
  'global' => {
    'op_queue' => 'wpq',
    'mon_osd_down_out_subtree_limit' => 'rack'
  },
  'mds' => {
    'mds_max_purge_ops_per_pg' => '10'
  },
  'mgr' => {
    'mgr/dashboard/server_addr' => 'localhost',
    'mgr/telemetry/contact' => 'me'
  }
);

1;

