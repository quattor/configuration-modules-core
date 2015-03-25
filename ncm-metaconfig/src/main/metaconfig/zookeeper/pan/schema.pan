declaration template metaconfig/zookeeper/schema;

include 'pan/types';

type zookeeper_main = {
    # minimal
    "tickTime" : long = 2000
    "dataDir" : string
    "clientPort" : long = 2181
    
    # regular
    "dataLogDir" ? string
    "globalOutstandingLimit" ? long
    "preAllocSize" ? long # in kB
    "snapCount" ? long
    "traceFile" ? string
    "maxClientCnxns" ? long
    "clientPortAddress" ? type_network_name
    "minSessionTimeout" ? long
    "maxSessionTimeout" ? long
    "fsync.warningthresholdms" ? long
    "autopurge.snapRetainCount" ? long
    "autopurge.purgeInterval" ? long
    "syncEnabled" ? boolean
    
    # cluster/ensemble
    "initLimit" : long = 10
    "syncLimit" : long = 5
    "electionAlg" ? long
    "leaderServes" ? boolean
}; 

type zookeeper_servers = {
    "hostname" : type_network_name
    "port" : long = 2888
    "leaderport" : long = 3888 
};

type zookeeper_server_config = {
    "main" : zookeeper_main
    "servers" : zookeeper_servers[]
};
