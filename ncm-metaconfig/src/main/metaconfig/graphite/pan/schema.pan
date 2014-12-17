declaration template metaconfig/graphite/schema;

include 'pan/types';

type carbon_storage_schema = {
    #  [name]
    #  pattern = regex
    #  retentions = timePerPoint:timeToStore, timePerPoint:timeToStore, ...
    "name" : string
    "pattern" : string
    "retentions" : string[]
};

type carbon_cache_storage_schemas = {
    "main" : carbon_storage_schema[]
};

type carbon_relay_rule = {
    #  [name]
    #  pattern = <regex>
    #  destinations = <list of destination addresses>
    #  continue = <boolean>  # default: False
    "name" : string
    "default" : boolean = false
    "pattern" : string
    "destinations" : string[]
    "continue" ? boolean = false
};

type carbon_relay_relay_rules = {
    "main" : carbon_relay_rule[]
};

type carbon_aggregation_rule = {
    #   output_template (frequency) = method input_pattern
    "output" : string
    "frequency" : string
    "method" : string with match(SELF,"^(sum|avg)$")
    "input" : string
};

type carbon_aggregator_aggregation_rules = {
    "main" : carbon_aggregation_rule[]
};

type carbon_common = {
    "line_receiver_interface" : type_fqdn = "0.0.0.0"

    "pickle_receiver_interface" : type_fqdn = "0.0.0.0"

    "use_flow_control" : boolean = true
    "use_whitelist" ? boolean = false

    "carbon_metric_prefix" ? string = "carbon"
    "carbon_metric_interval" ? long(0..) = 60
};

type carbon_cache = {
    include carbon_common
    "line_receiver_port" : long(0..) = 2003
    "pickle_receiver_port" : long(0..) = 2004

    "storage_dir" : string = "/var/lib/carbon/"
    "local_data_dir" : string = "/var/lib/carbon/whisper/"
    "whitelists_dir" : string = "/var/lib/carbon/lists/"
    "conf_dir" : string = "/etc/carbon/"
    "log_dir" : string = "/var/log/carbon/"
    "pid_dir" : string = "/var/run/"

    "user" : string = "carbon"

    "max_cache_size" : string = "inf"

    "max_updates_per_second" : long(0..) = 2000

    "max_creates_per_minute" : long(0..) = 200

    "enable_udp_listener" : boolean = false
    "udp_receiver_interface" : type_fqdn = "0.0.0.0"
    "udp_receiver_port" : long(0..) = 2003

    "use_insecure_unpickler" : boolean = false

    "cache_query_interface" : string = "0.0.0.0"
    "cache_query_port" : long(0..) = 7002

    "log_updates" : boolean = false

    # eg list("sales.#", "servers.linux.#", "#.utilization")
    # or all list("#")
    "bind_patterns" ? string[] 

    "whisper_autoflush" : boolean = false
    "whisper_sparse_create" ? boolean = false
    "whisper_lock_writes" ? boolean = false

    "enable_amqp" ? boolean = false
    "amqp_verbose" ? boolean = false
    "amqp_host" ? type_fqdn = "localhost"
    "amqp_port" ? long(0..) = 5672
    "amqp_vhost" ? string = "/"
    "amqp_user" ? string = "guest"
    "amqp_password" ? string = "guest"
    "amqp_exchange" ? string = "graphite"
    "amqp_metric_name_in_body" ? boolean = false

    "enable_manhole" ? boolean = false
    "manhole_interface" ? type_fqdn = "127.0.0.1"
    "manhole_port" ? long(0..) = 7222
    "manhole_user" ? string = "admin"
    "manhole_public_key" ? string
    
} = nlist();

type carbon_relay = {
    include carbon_common
    "line_receiver_port" : long(0..) = 2013
    "pickle_receiver_port" : long(0..) = 2014

    "relay_method" : string = "rules" with match(SELF,"^(consistent-hashing|rules)$")

    "replication_factor" : long(0..) = 1

    # the general form is ip:port:instance where the :instance part is
    # eg list("127.0.0.1:2004:a", "127.0.0.1:2104:b")
    "destinations" : string[] = list("127.0.0.1:2004")

    "max_datapoints_per_message" : long(0..) = 500
    "max_queue_size" : long(0..) = 10000

} = nlist();

type carbon_aggregator = {
    include carbon_common
    "line_receiver_port" : long(0..) = 2023
    "pickle_receiver_port" : long(0..) = 2024

    # the general form is ip:port:instance where the :instance part is
    # eg list("127.0.0.1:2004:a", "127.0.0.1:2104:b")
    "destinations" : string[] = list("127.0.0.1:2004")

    "replication_factor" : long(0..) = 1

    "max_queue_size" : long(0..) = 10000
    "max_datapoints_per_message" : long(0..) = 500
    "max_aggregation_intervals" : long(0..) = 5
} = nlist();

type carbon_config = {
    "cache" : carbon_cache 
    "cache_instances" ? carbon_cache{}
    "relay" : carbon_relay
    "aggregator" : carbon_aggregator
} = nlist();

