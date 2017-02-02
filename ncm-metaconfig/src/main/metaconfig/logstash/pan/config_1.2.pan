unique template metaconfig/logstash/config_1.2;

variable METACONFIG_LOGSTASH_VERSION ?= '1.2';
include format('metaconfig/logstash/schema_%s', METACONFIG_LOGSTASH_VERSION);

bind "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents" = type_logstash;

prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}";
"daemons/logstash" = "restart";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = format("logstash/%s/main" , METACONFIG_LOGSTASH_VERSION);
