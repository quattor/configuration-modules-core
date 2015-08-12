declaration template components/${project.artifactId}/schema-rgw;

@documentation{ ceph rados gateway config }
type ceph_radosgw_config = { 
    include ceph_daemon_config
    'host'      : string
    'keyring'   : string
    'rgw_socket_path' : string = ''
    'log_file'  : string = '/var/log/radosgw/client.radosgw.gateway.log'
    'rgw_frontends' : string = "\"civetweb port=8000\""
    'rgw_print_continue' : boolean = false
    'rgw_dns_name' : type_fqdn
    'rgw_enable_ops_log' : boolean = true
    'rgw_enable_usage_log' : boolean = true
    'user' ? string
};

@documentation{ ceph rados gateway type 
http://ceph.com/docs/master/radosgw/ 
}
type ceph_radosgw = {
    'config' ? ceph_radosgw_config
};

@documentation{ ceph rados gateway host }
type ceph_radosgwh = {
    'fqdn'      : type_fqdn
    'gateways'  : ceph_radosgw{}
};

