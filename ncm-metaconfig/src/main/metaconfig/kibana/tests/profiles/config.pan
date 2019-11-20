object template config;

include 'metaconfig/kibana/config';

prefix "/software/components/metaconfig/services/{/etc/kibana/kibana.yml}/contents";
"elasticsearch/url" = format("http://%s:9200", "mysupersecret.host.domain");
"kibana/index" = "kibana";
