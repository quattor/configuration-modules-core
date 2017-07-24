object template config_0.9;

# 2 4-core cpus
"/hardware/cpu" = list(dict("cores", 4), dict("cores", 4));

variable METACONFIG_ELASTICSEARCH_VERSION = '0.9';
include 'metaconfig/elasticsearch/config';

prefix "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}/contents/threadpool";
"bulk/size" = length(value("/hardware/cpu"));
"bulk/type" = "fixed";
"bulk/queue_size" = 500;
"search/size" = length(value("/hardware/cpu"));
"search/type" = "fixed";
"search/queue_size" = 500;
"index/size" = length(value("/hardware/cpu")) * value("/hardware/cpu/0/cores");
"index/type" = "fixed";
"index/queue_size" = 1000;

prefix "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}/contents";
"index/refresh" = 10;
"indices/memory/index_buffer_size" = "50%";
"index/translog/flush_threshold_ops" = 100000;
"index/number_of_replicas" = 1;
"bootstrap/mlockall" = true;
"network/host" = "myhost.mydomain";
"node/name" = "myname";
"discovery/zen/ping/unicast/hosts" = list('master1:1234', 'master2:5678');
