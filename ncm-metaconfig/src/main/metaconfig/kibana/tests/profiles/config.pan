object template config;

include 'metaconfig/kibana/config';

prefix "/software/components/metaconfig/services/{/etc/kibana/kibana.yml}/contents";
"elasticsearch_url" = format("http://%s:9200", "mysupersecret.host.domain");
