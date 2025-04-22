unique template metaconfig/prometheus/config;

include 'metaconfig/prometheus/schema';

bind "/software/components/metaconfig/services/{/etc/prometheus/prometheus.yml}/contents" = prometheus_server_config;

prefix "/software/components/metaconfig/services/{/etc/prometheus/prometheus.yml}";
"module" = "yaml";

bind "/software/components/metaconfig/services/{/etc/prometheus/rules.yml}/contents" = prometheus_rules_config;

prefix "/software/components/metaconfig/services/{/etc/prometheus/rules.yml}";
"module" = "yaml";
"contents" = dict();
