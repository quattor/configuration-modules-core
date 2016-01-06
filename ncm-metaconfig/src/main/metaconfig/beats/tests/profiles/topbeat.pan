object template topbeat;

include 'metaconfig/beats/topbeat';

prefix "/software/components/metaconfig/services/{/etc/topbeat/topbeat.yml}/contents/input";
"period" = 60;
"stats/cpu_per_core" = false;
prefix "/software/components/metaconfig/services/{/etc/topbeat/topbeat.yml}/contents/output/elasticsearch";
"hosts" = list('localhost:1234', 'otherhost:5678');
