unique template metaconfig/zookeeper/config;

include 'metaconfig/zookeeper/schema';

bind "/software/components/metaconfig/services/{/etc/zookeeper/conf/zoo.cfg}/contents" = zookeeper_server_config;

prefix "/software/components/metaconfig/services/{/etc/zookeeper/conf/zoo.cfg}";
"daemon/0" = "zookeeper-server";
"module" = "zookeeper/server";
"mode" = 0644;
