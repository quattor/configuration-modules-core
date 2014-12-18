unique template metaconfig/graylog2/config;

include 'metaconfig/graylog2/schema';

bind "/software/components/metaconfig/services/{/etc/graylog2.conf}/contents" = graylog2;

prefix "/software/components/metaconfig/services/{/etc/graylog2.conf}";
"module" = "graylog2/server";

prefix "/software/components/metaconfig/services/{/etc/graylog2.conf}/contents";
"syslog_listen_port" = 5678;
"rules_file" = "/etc/graylog2/graylog2.drl";
"amqp_enabled" = false;
"syslog_protocol" = "tcp";
