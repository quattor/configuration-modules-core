declaration template metaconfig/kafka/schema;

include 'pan/types';


type kafka_server_properties = {
    "advertised.listeners" ? string = "PLAINTEXT://localhost:9092"
    "broker.id" : long(0..)
    "group.initial.rebalance.delay.ms" ? long(0..)
    "inter.broker.listener.name" ? string
    "inter.broker.protocol.version" ? string with match(SELF, '^\d+\.\d+$')
    "listener.security.protocol.map" ? string
    "listeners" ? string = "PLAINTEXT://localhost:9092"
    "log.dirs" : absolute_file_path
    "log.message.format.version" ? string with match(SELF, '^\d+\.\d+$')
    "log.retention.hours" ? long(0..)
    "log.retention.check.interval.ms" ? long(0..)
    "log.segment.bytes" ? long(0..)
    "num.io.threads" ? long(1..)
    "num.network.threads" ? long(1..)
    "num.partitions" ? long(0..)
    "num.recovery.threads.per.data.dir" ? long(1..)
    "offsets.topic.replication.factor" ? long(1..)
    "socket.send.buffer.bytes" ? long(0..)
    "socket.receive.buffer.bytes" ? long(0..)
    "socket.request.max.bytes" ? long(0..)
    "zookeeper.connect" : string
    "zookeeper.connection.timeout.ms" ? long(100..)
};
