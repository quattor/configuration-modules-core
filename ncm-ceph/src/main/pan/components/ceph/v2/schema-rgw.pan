declaration template components/${project.artifactId}/v2/schema-rgw;

type type_quoted_string = string with match(SELF, '^".*"$');

@documentation{ configuration options for a ceph rados gateway instance }
type ceph_rgw_config = {
    'host' : string
    'keyring' : string
    'rgw_socket_path' : string = ''
    'log_file' : absolute_file_path = '/var/log/radosgw/client.radosgw.gateway.log'
    'rgw_frontends' : type_quoted_string = '"civetweb port=8000"' #Some bug in ceph config parsing
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
    'config' ? ceph_rgw_config
};

