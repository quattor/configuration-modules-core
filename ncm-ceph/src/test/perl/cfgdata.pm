package cfgdata;

use strict;
use warnings;

use Readonly;

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
osd_pool_default_min_size=2
osd_pool_default_size=3
public_network=192.168.0.0/20

[osd]
osd_max_scrubs=4
EOD

1;
