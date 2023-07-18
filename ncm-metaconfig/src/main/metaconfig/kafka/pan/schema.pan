declaration template metaconfig/kafka/schema;

include 'pan/types';

type kafka_server_properties = {
    "advertised.host.name" ? string_trimmed
    "advertised.listeners" ? string_trimmed = "PLAINTEXT://localhost:9092"
    "advertised.port" ? long(0..)
    "alter.config.policy.class.name" ? string_trimmed
    "alter.log.dirs.replication.quota.window.num" ? long(1..)
    "alter.log.dirs.replication.quota.window.size.seconds" ? long(1..)
    "authorizer.class.name" ? string_trimmed
    "auto.create.topics.enable" ? choice("true", "false")
    "auto.leader.rebalance.enable" ? choice("true", "false")
    "background.threads" ? long(1..)
    "broker.id" : long(0..)
    "broker.id.generation.enable" ? choice("true", "false")
    "broker.rack" ? string_trimmed
    "client.quota.callback.class" ? string_trimmed
    "compression.type" ? choice('uncompressed', 'zstd', 'lz4', 'snappy', 'gzip', 'producer')
    "connection.failed.authentication.delay.ms" ? long(0..)
    "connections.max.idle.ms" ? long(0..)
    "connections.max.reauth.ms" ? long(0..)
    "control.plane.listener.name" ? string_trimmed
    "controlled.shutdown.enable" ? choice("true", "false")
    "controlled.shutdown.max.retries" ? long(0..)
    "controlled.shutdown.retry.backoff.ms" ? long(0..)
    "controller.socket.timeout.ms" ? long(0..)
    "create.topic.policy.class.name" ? string_trimmed
    "default.replication.factor" ? long(0..)
    "delegation.token.expiry.check.interval.ms" ? long(1..)
    "delegation.token.expiry.time.ms" ? long(1..)
    "delegation.token.master.key" ? string_trimmed  # password
    "delegation.token.max.lifetime.ms" ? long(1..)
    "delete.records.purgatory.purge.interval.requests" ? long(0..)
    "delete.topic.enable" ? choice("true", "false")
    "fetch.purgatory.purge.interval.requests" ? long(0..)
    "group.initial.rebalance.delay.ms" ? long(0..)
    "group.max.session.timeout.ms" ? long(0..)
    "group.max.size" ? long(1..)
    "group.min.session.timeout.ms" ? long(0..)
    "host.name" ? string
    "inter.broker.listener.name" ? string
    "inter.broker.protocol.version" ? string with match(SELF, '^\d+\.\d+$')
    "kafka.metrics.polling.interval.secs" ? long(1..)
    "kafka.metrics.reporters" ? string_trimmed[]
    "leader.imbalance.check.interval.seconds" ? long(0..)
    "leader.imbalance.per.broker.percentage" ? long(0..)
    "listener.security.protocol.map" ? string
    "listeners" ? string = "PLAINTEXT://localhost:9092"
    "log.cleaner.backoff.ms" ? long(0..)
    "log.cleaner.dedupe.buffer.size" ? long(0..)
    "log.cleaner.delete.retention.ms" ? long(0..)
    "log.cleaner.enable" ? choice("true", "false")
    "log.cleaner.io.buffer.load.factor" ? double
    "log.cleaner.io.buffer.size" ? long(0..)
    "log.cleaner.io.max.bytes.per.second" ? double
    "log.cleaner.max.compaction.lag.ms" ? long(0..)
    "log.cleaner.min.cleanable.ratio" ? double
    "log.cleaner.min.compaction.lag.ms" ? long(0..)
    "log.cleaner.threads" ? long(0..)
    "log.cleanup.policy" ? choice("compact", "delete")
    "log.dir" ? absolute_file_path
    "log.dirs" : absolute_file_path
    "log.flush.interval.messages" ? long(1..)
    "log.flush.interval.ms" ? long(0..)
    "log.flush.offset.checkpoint.interval.ms" ? long(0..)
    "log.flush.scheduler.interval.ms" ? long(0..)
    "log.flush.start.offset.checkpoint.interval.ms" ? long(0..)
    "log.index.interval.bytes" ? long(0..)
    "log.index.size.max.bytes" ? long(0..)
    "log.message.downconversion.enable" ? choice("true", "false")
    "log.message.format.version" ? string with match(SELF, '^\d+\.\d+$')
    "log.message.timestamp.difference.max.ms" ? long(0..)
    "log.message.timestamp.type" ? choice('CreateTime', 'LogAppendTime')
    "log.preallocate" ? choice("true", "false")
    "log.retention.bytes" ? long(0..)
    "log.retention.check.interval.ms" ? long(1..)
    "log.retention.hours" ? long(0..)
    "log.retention.minutes" ? long(0..)
    "log.retention.ms" ? long(0..)
    "log.roll.hours" ? long(1..)
    "log.roll.jitter.hours" ? long(0..)
    "log.roll.jitter.ms" ? long(0..)
    "log.roll.ms" ? long(0..)
    "log.segment.bytes" ? long(0..)
    "log.segment.delete.delay.ms" ? long(0..)
    "max.connections" ? long(0..)
    "max.connections.per.ip" ? long(0..)
    "max.connections.per.ip.overrides" ? string
    "max.incremental.fetch.session.cache.slots" ? long(0..)
    "message.max.bytes" ? long(0..)
    "metric.reporters" ? string_trimmed[]
    "metrics.num.samples" ? long(1..)
    "metrics.recording.level" ? string_trimmed
    "metrics.sample.window.ms" ? long(1..)
    "min.insync.replicas" ? long(1..)
    "num.io.threads" ? long(1..)
    "num.network.threads" ? long(1..)
    "num.partitions" ? long(1..)
    "num.recovery.threads.per.data.dir" ? long(1..)
    "num.replica.alter.log.dirs.threads" ? long(0..)
    "num.replica.fetchers" ? long(0..)
    "offset.metadata.max.bytes" ? long(0..)
    "offsets.commit.required.acks" ? long(0..)
    "offsets.commit.timeout.ms" ? long(1..)
    "offsets.load.buffer.size" ? long(1..)
    "offsets.retention.minutes" ? long(1..)
    "offsets.topic.compression.codec" ? long(0..)
    "offsets.topic.num.partitions" ? long(1..)
    "offsets.topic.replication.factor" ? long(1..)
    "offsets.topic.segment.bytes" ? long(1..)
    "password.encoder.cipher.algorithm" ? string_trimmed
    "password.encoder.iterations" ? long(0..)
    "password.encoder.key.length" ? long(0..)
    "password.encoder.keyfactory.algorithm" ? string
    "password.encoder.old.secret" ? string_trimmed  # password
    "password.encoder.secret" ? string_trimmed  # password
    "port" ? long(0..)
    "principal.builder.class" ? string_trimmed
    "producer.purgatory.purge.interval.requests" ? long(0..)
    "queued.max.request.bytes" ? long(0..)
    "queued.max.requests" ? long(1..)
    "quota.consumer.default" ? long(1..)  # deprecated
    "quota.producer.default" ? long(1..)  # deprecated
    "quota.window.num" ? long(1..)
    "quota.window.size.seconds" ? long(1..)
    "replica.fetch.backoff.ms" ? long(0..)
    "replica.fetch.max.bytes" ? long(0..)
    "replica.fetch.min.bytes" ? long(1..)
    "replica.fetch.response.max.bytes" ? long(0..)
    "replica.fetch.wait.max.ms" ? long(0..)
    "replica.high.watermark.checkpoint.interval.ms" ? long(0..)
    "replica.lag.time.max.ms" ? long(0..)
    "replica.selector.class" ? string_trimmed
    "replica.socket.receive.buffer.bytes" ? long(0..)
    "replica.socket.timeout.ms" ? long(0..)
    "replication.quota.window.num" ? long(1..)
    "replication.quota.window.size.seconds" ? long(1..)
    "request.timeout.ms" ? long(0..)
    "reserved.broker.max.id" ? long(0..)
    "sasl.client.callback.handler.class" ? string
    "sasl.enabled.mechanisms" ? string_trimmed[]
    "sasl.jaas.config" ? string_trimmed  # password
    "sasl.kerberos.kinit.cmd" ? absolute_file_path
    "sasl.kerberos.min.time.before.relogin" ? long(0..)
    "sasl.kerberos.principal.to.local.rules" ? string_trimmed[]
    "sasl.kerberos.service.name" ? string_trimmed
    "sasl.kerberos.ticket.renew.jitter" ? double
    "sasl.kerberos.ticket.renew.window.factor" ? double
    "sasl.login.callback.handler.class" ? string_trimmed
    "sasl.login.class" ? string_trimmed
    "sasl.login.refresh.buffer.seconds" ? long(0..)
    "sasl.login.refresh.min.period.seconds" ? long(0..)
    "sasl.login.refresh.window.factor" ? double
    "sasl.login.refresh.window.jitter" ? double
    "sasl.mechanism.inter.broker.protocol" ? string_trimmed
    "sasl.server.callback.handler.class" ? string_trimmed
    "security.inter.broker.protocol" ? choice('PLAINTEXT', 'SSL', 'SASL_PLAINTEXT', 'SASL_SSL')
    "security.providers" ? string_trimmed
    "socket.receive.buffer.bytes" ? long(0..)
    "socket.request.max.bytes" ? long(1..)
    "socket.send.buffer.bytes" ? long(0..)
    "ssl.cipher.suites" ? string_trimmed[]
    "ssl.client.auth" ? choice('required', 'requested', 'none')
    "ssl.enabled.protocols" ? string_trimmed[]
    "ssl.endpoint.identification.algorithm" ? string_trimmed
    "ssl.key.password" ? string_trimmed  # password
    "ssl.keymanager.algorithm" ? string_trimmed
    "ssl.keystore.location" ? absolute_file_path
    "ssl.keystore.password" ? string_trimmed # password
    "ssl.keystore.type" ? choice('JKS', 'PKCS12', 'PEM')
    "ssl.principal.mapping.rules" ? string_trimmed
    "ssl.protocol" ? choice('TLSv1.2', 'TLSv1.3')
    "ssl.provider" ? string_trimmed
    "ssl.secure.random.implementation" ? string_trimmed
    "ssl.trustmanager.algorithm" ? string_trimmed
    "ssl.truststore.location" ? absolute_file_path
    "ssl.truststore.password" ? string_trimmed  # password
    "ssl.truststore.type" ? choice('JKS', 'PKCS12', 'PEM')
    "transaction.abort.timed.out.transaction.cleanup.interval.ms" ? long(1..)
    "transaction.max.timeout.ms" ? long(1..)
    "transaction.remove.expired.transaction.cleanup.interval.ms" ? long(1..)
    "transaction.state.log.load.buffer.size" ? long(1..)
    "transaction.state.log.min.isr" ? long(1..)
    "transaction.state.log.num.partitions" ? long(1..)
    "transaction.state.log.replication.factor" ? long(1..)
    "transaction.state.log.segment.bytes" ? long(1..)
    "transactional.id.expiration.ms" ? long(1..)
    "unclean.leader.election.enable" ? choice("true", "false")
    "zookeeper.connect" : string
    "zookeeper.connection.timeout.ms" ? long(100..)
    "zookeeper.max.in.flight.requests" ? long(1..)
    "zookeeper.session.timeout.ms" ? long(0..)
    "zookeeper.set.acl" ? choice("true", "false")
    "zookeeper.sync.time.ms" ? long(0..)
};
