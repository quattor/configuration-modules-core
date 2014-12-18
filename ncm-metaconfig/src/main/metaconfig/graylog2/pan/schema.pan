declaration template metaconfig/graylog2/schema;

include 'pan/types';

type syslogprot_string = string with match (SELF, "tcp|udp");

type graylog2 = {
    "syslog_listen_port" : long = 514
    "syslog_protocol" :  syslogprot_string = 'udp'
    "elasticsearch_url" : type_absoluteURI = 'http://localhost:9200/'
    "elasticsearch_index_name" : string = 'graylog2'
    "force_syslog_rdns" : boolean = false
    "mongodb_useauth" : boolean = false
    "mongodb_user" ? string
    "mongodb_password" ? string
    "mongodb_host" : type_fqdn = 'localhost'
    'mongodb_replica_set' ? string
    "mongodb_database" : string = 'graylog2'
    "mongodb_port" : long = 27017
# interval (in seconds) the message batch is sent. Example: If you leave the standard values (mq_batch_size = 4000, mq_poll_freq = 1), Graylog2 will index 4000 messages
    "mq_batch_size" : long = 4000
    "mq_poll_freq" : long = 1
# 0 = unlimited queue size (default)
    "mq_max_size" : long = 0
    "mongodb_max_connections" : long = 100
    "mongodb_threads_allowed_to_block_multiplier" : long = 5
    "use_gelf" : boolean = true
    "gelf_listen_address" : type_ip = '0.0.0.0'
    "gelf_listen_port" : type_port = 12201
    "rules_file" ? string
    "amqp_enabled" : boolean = false
    "amqp_subscribed_queues" ? string
    "amqp_host" : string = 'localhost'
    "amqp_port" : long = 5672
    "amqp_username" : string = 'guest'
    "amqp_password" : string = 'guest'
    "amqp_virtualhost" : string = '/'
    "forwarder_loggly_timeout" : long = 3
};

