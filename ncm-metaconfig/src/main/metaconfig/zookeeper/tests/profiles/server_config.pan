object template server_config;

include 'metaconfig/zookeeper/config';

prefix "/software/components/metaconfig/services/{/etc/zookeeper/zoo.cfg}/contents";
"main/dataDir" = "/var/lib/zookeeper";
"main/4lw.commands.whitelist" = list("stat" , "srvr" , "mntr");

"servers" =  list(
    dict("hostname", "host1.domain"),
    dict("hostname", "host2.domain"),
    dict("hostname", "host3.domain"),
);
