unique template metaconfig/elasticsearch/config_0.9;

include 'metaconfig/elasticsearch/schema_0.9';

bind "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}/contents" = elasticsearch_09_service;

prefix "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}";
"module" = "yaml";
"mode" = 0640;
"group" = "elasticsearch";
"daemons" = dict("elasticsearch", "restart");
