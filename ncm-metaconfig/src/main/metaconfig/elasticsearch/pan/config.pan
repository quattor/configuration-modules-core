unique template metaconfig/elasticsearch/config;

variable METACONFIG_ELASTICSEARCH_VERSION ?= '5.0';
include format('metaconfig/elasticsearch/config_%s', METACONFIG_ELASTICSEARCH_VERSION);
