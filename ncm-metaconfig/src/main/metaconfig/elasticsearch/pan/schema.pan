declaration template metaconfig/elasticsearch/schema;

include 'pan/types';

type elasticsearch_cluster = {
    "name" ? string
};

type elasticsearch_node = {
    "master" ? boolean
    "name" ? string
    "rack" ? string
    "data" ? boolean
};

type elasticsearch_index_search = {
    "showlog" ? string{}
};


type elasticsearch_translog = {
    "flush_threshold_ops" : long = 5000
};

type elasticsearch_index = {
    "number_of_shards" ? long(0..)
    "number_of_replicas" ? long(0..)
    "search" ? elasticsearch_index_search
    "refresh" ? long(0..)
    "translog" ? elasticsearch_translog
};

type elasticsearch_recovery = {
    "max_size_per_sec" : long = 0
    "concurrent_streams" : long = 5
};

type elasticsearch_memory = {
    "index_buffer_size" : string with match(SELF, '^\d+%+')
};

type elasticsearch_indices = {
    "recovery" ? elasticsearch_recovery
    "memory" ? elasticsearch_memory
};

type elasticsearch_gw = {
    "recover_after_nodes" ? long
    "recover_after_time" ? long
};

type elasticsearch_network = {
    "host" ? type_hostname
    "bind_host" ? type_hostname
    "publish_host" ? type_hostname
};

type elasticsearch_monitoring = {
    "enabled" : boolean = false
};

type elasticsearch_thread_search = {
    "type" : string with match(SELF, "^(fixed|cached|blocking)$")
    "size" : long(0..)
    "min" ? long
    "queue_size" ? long(0..)
    "reject_policy" ? string with match(SELF, "^(caller|abort)$")
};

@documentation{
    Thread pool management.  See
    http://www.elasticsearch.org/guide/reference/modules/threadpool/
@}
type elasticsearch_threadpool = {
    "search" : elasticsearch_thread_search
    "index" : elasticsearch_thread_search
    "get" ? elasticsearch_thread_search
    "bulk" ? elasticsearch_thread_search
    "warmer" ? elasticsearch_thread_search
    "refresh" ? elasticsearch_thread_search
};

type elasticsearch_bootstrap = {
    "mlockall" ? boolean
};

type elasticsearch_transport = {
    "host" ? type_hostname
};

type elasticsearch_discovery_zen_ping_unicast = {
    "hosts" ? type_hostport[]
};

type elasticsearch_discovery_zen_ping = {
    "unicast" ? elasticsearch_discovery_zen_ping_unicast
};

@documentation{
    Control discovery process
    https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery-zen.html
}
type elasticsearch_discovery_zen = {
    "ping" ? elasticsearch_discovery_zen_ping
    "ping_timeout" ? long(0..)
    "join_timeout" ? long(0..)
};

type elasticsearch_discovery = {
    "zen" ? elasticsearch_discovery_zen
};

type elasticsearch_service = {
    "node" ? elasticsearch_node
    "index" ? elasticsearch_index
    "gateway" ? elasticsearch_gw
    "indices" ? elasticsearch_indices
    "network" : elasticsearch_network = nlist("host", "localhost")
    "monitor.jvm" : elasticsearch_monitoring = nlist()
    "threadpool" ? elasticsearch_threadpool
    "bootstrap" ? elasticsearch_bootstrap
    "cluster" ? elasticsearch_cluster
    "transport" ? elasticsearch_transport
    "discovery" ? elasticsearch_discovery
};
