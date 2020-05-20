unique template metaconfig/elasticsearch/config_6.3;

variable METACONFIG_ELASTICSEARCH_VERSION ?= '6.3';
include 'metaconfig/elasticsearch/schema';

bind "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}/contents" = elasticsearch_service;

prefix "/software/components/metaconfig/services/{/etc/elasticsearch/elasticsearch.yml}";
"module" = "yaml";
"mode" = 0640;
"group" = "elasticsearch";
"daemons" = dict("elasticsearch", "restart");
