object template filebeat;

include 'metaconfig/beats/filebeat';

prefix "/software/components/metaconfig/services/{/etc/filebeat/filebeat.yml}/contents/filebeat";
"prospectors" = append(dict(
    "paths", list('/path/1', '/path/2/*'),
    "fields", dict("type", "special"),
));
"prospectors" = append(dict(
    "paths", list('/path/1b', '/path/2b/*'),
    "fields", dict("typeb", "specialb"),
));


prefix "/software/components/metaconfig/services/{/etc/filebeat/filebeat.yml}/contents/output/logstash";
"hosts" = list('localhost:1234', 'otherhost:5678');
"loadbalance" = true;

prefix "/software/components/metaconfig/services/{/etc/filebeat/filebeat.yml}/contents/output/console";
"pretty" = true;
