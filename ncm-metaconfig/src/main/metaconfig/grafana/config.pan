unique template metaconfig/grafana/config;

include 'metaconfig/grafana/schema';

bind "/software/components/metaconfig/services/{/etc/grafana/grafana.ini}/contents" = grafana_ini;

prefix "/software/components/metaconfig/services/{/etc/grafana/grafana.ini}";
"module" = "tiny";
