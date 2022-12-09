declaration template metaconfig/elasticsearch/schema_8.1;

@{version specific types for Elasticsearch version 8.1 and later}

type elasticsearch_bootstrap = {
    "memory_lock" ? boolean
};

type elasticsearch_path = {
    "repo" ? absolute_file_path[]
    "data" : absolute_file_path
    "logs" : absolute_file_path
};

@{fixed thread pool}
type elasticsearch_thread_pool_fixed = {
    "size" ? long(0..)
    "queue_size" ? long(-1..)
};

@{scaling thread pool}
type elasticsearch_thread_pool_scaling = {
    "core" ? long(1..)
    "max" ? long(1..)
    @{time in seconds to keep idle thread in thread pool}
    "keep_alive" ? long(0..)
};

@documentation{
    Thread pool management.  See
    http://www.elasticsearch.org/guide/reference/modules/threadpool/
@}
type elasticsearch_threadpool = {
    "generic" ? elasticsearch_thread_pool_scaling
    "search" ? elasticsearch_thread_pool_fixed
    "index" ? elasticsearch_thread_pool_fixed
    "get" ? elasticsearch_thread_pool_fixed
    "write" ? elasticsearch_thread_pool_fixed  # This replaces the bulk setting, starting with 6.3.0
    "snapshot" ? elasticsearch_thread_pool_scaling
    "warmer" ? elasticsearch_thread_pool_scaling
    "refresh" ? elasticsearch_thread_pool_scaling
    "listener" ? elasticsearch_thread_pool_scaling
};

type elasticsearch_xpack_transport_ssl = {
    "enabled" : boolean
    "key" : string
    "certificate" : string
    "verification_mode" : string with match(SELF, "^(certificate|full|none)$")
    "certificate_authorities" : absolute_file_path[]
};

type elasticsearch_xpack_transport = {
    "ssl" : elasticsearch_xpack_transport_ssl
};

type elasticsearch_xpack_http_ssl = {
    "enabled" : boolean
    "key" : string
    "certificate" : string
    "verification_mode" : string with match(SELF, "^(certificate|full|none)$")
    "certificate_authorities" : absolute_file_path[]
};

type elasticsearch_xpack_http = {
    "ssl" : elasticsearch_xpack_http_ssl
};

type elasticsearch_xpack_security = {
    "enabled" : boolean
    "transport" : elasticsearch_xpack_transport
    "http" : elasticsearch_xpack_http
};

type elasticsearch_xpack = {
    "security" : elasticsearch_xpack_security
};

type elasticsearch_service = {
    "node" ? elasticsearch_node
    "index" ? elasticsearch_index
    "gateway" ? elasticsearch_gw
    "indices" ? elasticsearch_indices
    "network" : elasticsearch_network = dict("host", "localhost")
    "monitor.jvm.gc" : elasticsearch_monitoring = dict()
    "thread_pool" ? elasticsearch_threadpool
    "bootstrap" ? elasticsearch_bootstrap
    "cluster" ? elasticsearch_cluster
    "transport" ? elasticsearch_transport
    "discovery" ? elasticsearch_discovery
    "path" : elasticsearch_path
    "processors" ? long(1..)
    "xpack" ? elasticsearch_xpack
};
