object template config_7.0;

# 2 4-core cpus
"/hardware/cpu" = list(dict("cores", 4), dict("cores", 4));

# 7.0 is default
include 'metaconfig/elasticsearch/config';

prefix "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}/contents/thread_pool";
"index/size" = length(value("/hardware/cpu")) * value("/hardware/cpu/0/cores");
"index/queue_size" = 1000;
"listener/core" = 2;
"listener/max" = 4;
"listener/keep_alive" = 30 * 60;

prefix "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}/contents";
"processors" = 4;
"indices/memory/index_buffer_size" = "50%";
"index/number_of_replicas" = 1;
"bootstrap/memory_lock" = true;
"network/host" = "myhost.mydomain";
"node/name" = "myname";
"discovery/zen/ping/unicast/hosts" = list('master1:1234', 'master2:5678');
"path/data" = "/somewhere/elsewhere";
"path/logs" = "/somewhere/elsewhere/logs";

