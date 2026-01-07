unique template metaconfig/prometheus/alertmanager;

include 'metaconfig/prometheus/schema';

bind "/software/components/metaconfig/services/{/etc/prometheus/alertmanager.yml}/contents" = alertmanager_server_config;

prefix "/software/components/metaconfig/services/{/etc/prometheus/alertmanager.yml}";
"module" = "yaml";
