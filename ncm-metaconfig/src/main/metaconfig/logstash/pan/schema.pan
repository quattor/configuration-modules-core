declaration template metaconfig/logstash/schema;

include 'metaconfig/logstash/version';
include format('metaconfig/logstash/schema_%s', METACONFIG_LOGSTASH_VERSION);
