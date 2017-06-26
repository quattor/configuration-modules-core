declaration template metaconfig/elasticsearch/schema_0.9;

@{version specific types for Elasticsearch version 0.9 until (but not including) 5.0}

type elasticsearch_bootstrap = {
    "mlockall" ? boolean
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

type elasticsearch_service = {
    "node" ? elasticsearch_node
    "index" ? elasticsearch_index
    "gateway" ? elasticsearch_gw
    "indices" ? elasticsearch_indices
    "network" : elasticsearch_network = dict("host", "localhost")
    "monitor.jvm" : elasticsearch_monitoring = dict()
    "threadpool" ? elasticsearch_threadpool
    "bootstrap" ? elasticsearch_bootstrap
    "cluster" ? elasticsearch_cluster
    "transport" ? elasticsearch_transport
    "discovery" ? elasticsearch_discovery
};
