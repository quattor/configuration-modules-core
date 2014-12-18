unique template metaconfig/logstash/config;

include 'metaconfig/logstash/schema';

bind "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents" = type_logstash;

variable METACONFIG_LOGSTASH_VERSION ?= '1.2';

prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}";
"daemon/0" = "logstash";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = format("logstash/%s/main" , METACONFIG_LOGSTASH_VERSION);

