declaration template metaconfig/kibana/schema;

include 'pan/types';

type kibana_service = {
    "port" : type_port = 5601
    "host" : type_hostname = "localhost.localdomain" # not insecure shipped default "0.0.0.0"
    "elasticsearch_url" : type_absoluteURI = "http://localhost:9200"
    "elasticsearch_preserve_host" : boolean = true
    "kibana_index" : string = ".kibana"

    "kibana_elasticsearch_username" ? string
    "kibana_elasticsearch_password" ? string

    "kibana_elasticsearch_client_crt" ? string
    "kibana_elasticsearch_client_key" ? string

    "ca" ? string

    "default_app_id" : string = "discover"

    "ping_timeout" ? long(0..) = 1500

    "request_timeout" : long(1..) = 300000

    "shard_timeout" : long(0..) = 0 # 0 means disable

    "startup_timeout" ? long(0..) = 5000

    "verify_ssl" : boolean = true

    "ssl_key_file" ? string
    "ssl_cert_file" ? string

    "pid_file" ? string = '/var/run/kibana.pid'

    "log_file" ? string = './kibana.log'

    "bundled_plugin_ids" : list = list(
        'plugins/dashboard/index',
        'plugins/discover/index',
        'plugins/doc/index',
        'plugins/kibana/index',
        'plugins/markdown_vis/index',
        'plugins/metric_vis/index',
        'plugins/settings/index',
        'plugins/table_vis/index',
        'plugins/vis_types/index',
        'plugins/visualize/index',
        )
};
