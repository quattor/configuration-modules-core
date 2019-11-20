object template config;

variable METACONFIG_KIBANA_VERSION = "7.0";

include 'metaconfig/kibana/config';

prefix "/software/components/metaconfig/services/{/etc/kibana/kibana.yml}/contents";
"elasticsearch/hosts" = format("http://%s:9200", "mysupersecret.host.domain");
"elasticsearch/ssl.verificationMode" = "none";
"kibana/index" = ".kibana";

