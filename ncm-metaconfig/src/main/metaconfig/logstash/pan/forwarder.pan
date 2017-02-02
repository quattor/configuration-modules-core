unique template metaconfig/logstash/forwarder;


variable METACONFIG_LOGSTASH_VERSION ?= '1.2';
include format("metaconfig/logstash/forwarder_%s", METACONFIG_LOGSTASH_VERSION);
