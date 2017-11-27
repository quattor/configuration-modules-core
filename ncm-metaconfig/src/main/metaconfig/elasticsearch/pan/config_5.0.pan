unique template metaconfig/elasticsearch/config_5.0;

include 'metaconfig/elasticsearch/schema_5.0';

bind "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}/contents" = elasticsearch_50_service;

prefix "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}";
"module" = "yaml";
"mode" = 0640;
"group" = "elasticsearch";
"daemons" = dict("elasticsearch", "restart");
