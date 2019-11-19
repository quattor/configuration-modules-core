unique template metaconfig/zookeeper/config;

include 'metaconfig/zookeeper/schema';

bind "/software/components/metaconfig/services/{/etc/zookeeper/zoo.cfg}/contents" = zookeeper_server_config;

prefix "/software/components/metaconfig/services/{/etc/zookeeper/zoo.cfg}";
"daemons/zookeeper" = "restart";
"module" = "zookeeper/server";
"mode" = 0644;
