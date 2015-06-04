unique template metaconfig/elasticsearch/config;

include 'metaconfig/elasticsearch/schema';

bind "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}/contents" = elasticsearch_service;

prefix "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}";
"module" = "yaml";
"mode" = 0644;
"daemons" = dict("elasticsearch", "restart");
