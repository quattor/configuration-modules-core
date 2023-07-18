object template config;

include 'metaconfig/kafka/config';

variable KAFKA_DATA_DIR ?= "/var/lib/kafka";
variable KAFKA_INTERNAL_LISTENING_PROTOCOL ?= "PLAINTEXT";
variable KAFKA_EXTERNAL_LISTENING_PROTOCOL ?= "PLAINTEXT";
variable KAFKA_EXTERNAL_LOG_LISTENING_PROTOCOL ?= "PLAINTEXT";
variable KAFKA_INTERNAL_LISTENING_PORT ?= 9092;
variable KAFKA_EXTERNAL_LISTENING_PORT ?= 9093;
variable KAFKA_EXTERNAL_LOG_LISTENING_PORT ?= 9094;

variable HOSTNAME = "kafka";
variable CLUSTER_NAME = "cluster";
variable KAFKA_BROKER_ID = 42;
variable KAFKA_ZOOKEEPER_SERVERS = "zk1.cluster.log,zk2.cluster.log";

variable KAFKA_INTERNAL_LISTENER ?= format("INTERNAL://%s.%s.log:%d",
    HOSTNAME,
    CLUSTER_NAME,
    KAFKA_INTERNAL_LISTENING_PORT);

variable KAFKA_EXTERNAL_LISTENER ?= format("EXTERNAL://%s.%s.os:%d",
    HOSTNAME,
    CLUSTER_NAME,
    KAFKA_EXTERNAL_LISTENING_PORT);

variable KAFKA_EXTERNAL_LOG_LISTENER ?= format("EXTERNAL_LOG://%s.%s.log:%d",
    HOSTNAME,
    CLUSTER_NAME,
    KAFKA_EXTERNAL_LOG_LISTENING_PORT);

# the kafka service.properties
prefix "/software/components/metaconfig/services/{/etc/kafka/server.properties}/contents";

"advertised.listeners" = format("%s,%s,%s",
    KAFKA_INTERNAL_LISTENER,
    KAFKA_EXTERNAL_LISTENER,
    KAFKA_EXTERNAL_LOG_LISTENER);
"broker.id" = KAFKA_BROKER_ID;
"listeners" = format("%s,%s,%s",
    KAFKA_INTERNAL_LISTENER,
    KAFKA_EXTERNAL_LISTENER,
    KAFKA_EXTERNAL_LOG_LISTENER);
"listener.security.protocol.map" = format("EXTERNAL:%s,INTERNAL:%s,EXTERNAL_LOG:%s",
    KAFKA_INTERNAL_LISTENING_PROTOCOL,
    KAFKA_EXTERNAL_LISTENING_PROTOCOL,
    KAFKA_EXTERNAL_LOG_LISTENING_PROTOCOL
);
"inter.broker.listener.name" = "INTERNAL";
"zookeeper.connect" = KAFKA_ZOOKEEPER_SERVERS;
"log.dirs" = KAFKA_DATA_DIR;
