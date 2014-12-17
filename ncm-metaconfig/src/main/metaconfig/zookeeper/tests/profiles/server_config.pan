object template server_config;

include 'metaconfig/zookeeper/config';

prefix "/software/components/metaconfig/services/{/etc/zookeeper/conf/zoo.cfg}/contents";
"main/dataDir" = "/var/lib/zookeeper";
"servers" =  list(
    nlist("hostname", "host1.domain"),
    nlist("hostname", "host2.domain"),
    nlist("hostname", "host3.domain"),
);
