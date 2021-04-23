declaration template metaconfig/logstash/schema_7.0;

@{ Schema for logstash inputs, outputs and filters. See
https://www.elastic.co/guide/en/logstash/5.0/index.html for all the details.
}

include 'pan/types';

type logstash_port_range = long(1..)[] with length(SELF) == 2;

type logstash_ssl = {
    "ssl_cert" ? string
    "ssl_key" ? string
    "ssl_key_passphrase" ? string
    "ssl_enable" ? boolean
    "ssl_verify" ? boolean
};

type logstash_conditional_expression = {
    # [join] [[left] test] right (eg: and left > right; ! right;)
    "join" ? string with match(SELF, '^(and|or|nand|xor)$')
    "left" : string
    "test" ? string with match(SELF, '^(==|!=|<|>|<=|>=|=~|!~|in|not in|!)$')
    "right" ? string
};

# no nesting (yet)
type logstash_conditional = {
    # ifelseif: first one is 'if', rest is 'if else'
    # ifelseifelse: first one is 'if', last is 'else', rest is 'if else'
    "type" : string = 'if' with match(SELF, '^(if|if else|else|ifelseif|ifelseifelse)$')
    "expr" : logstash_conditional_expression[]
};

@{ Common portion for all plugins }
type logstash_plugin_common = {
    @{using _conditional to avoid name clash with plugin option name.
      The conditional is only for the single plugin and has to be type 'if' (the default).}
    "_conditional" ? logstash_conditional with { if (SELF['type'] != 'if') {
        error('plugin _conditional has to be type if (the default)'); }; true;
    }
};

# list not complete at all
type logstash_codec_charset = string with match(SELF, "^(UTF-8|locale|external|filesystem|internal)$");

type logstash_codec_common = {
    # there are codecs without any values to set. this should stay empty?
};

type logstash_codec_plain = {
    include logstash_codec_common
    "charset" ? logstash_codec_charset
    "format" ? string
};

type logstash_codec_json = {
    include logstash_codec_common
    "charset" ? logstash_codec_charset
};

type logstash_input_codec = {
    "json" ? logstash_codec_json
    "plain" ? logstash_codec_plain
} with length(SELF) == 1;

@{ Common portion for all input plugins }
type logstash_input_plugin_common = {
    include logstash_plugin_common
    "type" : string
    "debug" ? boolean
    "tags" ? string[]
    "add_field" ? string{}
    "codec" ? string with match(SELF, '^(plain|json)$')
};

@{ File-based input }
type logstash_input_file = {
    include logstash_input_plugin_common
    "path" : string[]
    "exclude" ? string[]
    "sincedb_path" ? string
    "sincedb_write_interval" ? long(1..)
    "stat_interval" : long(1..) = 1
    "start_position" ? string with match(SELF, '^(beginning|end)$')
};

@{ Collecting from tcp }
type logstash_input_tcp = {
    include logstash_input_plugin_common
    include logstash_ssl
    "ssl_extra_chain_certs" ? string[]
    "port" : type_port
    "host" ? type_hostname
    "mode" ? string = "server" with match(SELF, ("server|client"))
};

@{ Collecting from udp }
type logstash_input_udp = {
    include logstash_input_plugin_common
    include logstash_ssl
    "port" : type_port
    "host" ? type_hostname
};

@{ GELF input }
type logstash_input_gelf = {
    include logstash_input_plugin_common
    "port" : type_port = 12201
    "host" ? type_hostname
    "remap" : boolean = true
};

@{ Lumberjack/logstash-forwarder input }
type logstash_input_lumberjack = {
    include logstash_input_plugin_common
    "port" : type_port = 12201
    "host" ? type_hostname
    "ssl_certificate" : string
    "ssl_key" : string
    "ssl_key_passphrase" ? string
};

@{ beats input }
type logstash_input_beats = {
    include logstash_input_lumberjack
    'ssl_certificate_authorities' ? string[]
    'ssl' ? boolean
};

@{ zeromq input }
type logstash_input_zeromq = {
    include logstash_input_plugin_common
    "address" ? string[] = list("tcp://*:2120")
    "mode" ? string = "server" with match(SELF, ("server|client"))
    "sender" ? string
    "sockopt" ? dict()
    "topic" ? string[]
    "topology" : string with match(SELF, ("pushpull|pubsub|pair"))
};

@{ kafka input }
type logstash_input_kafka = {
    include logstash_input_plugin_common
    "auto_commit_interval_ms" ? string
    "auto_offset_reset" ? string
    "bootstrap_servers" ? string
    "check_crcs" ? string
    "client_id" ? string
    "connections_max_idle_ms" ? string
    "consumer_threads" ? long(0..)
    "decorate_events" ? boolean
    "enable_auto_commit" ? string
    "exclude_internal_topics" ? string
    "fetch_max_bytes" ? string
    "fetch_max_wait_ms" ? string
    "fetch_min_bytes" ? string
    "group_id" ? string
    "heartbeat_interval_ms" ? string
    "jaas_path" ? absolute_file_path
    "kerberos_config" ? absolute_file_path
    "key_deserializer_class" ? string
    "max_partition_fetch_bytes" ? string
    "max_poll_interval_ms" ? string
    "max_poll_records" ? string
    "metadata_max_age_ms" ? string
    "partition_assignment_strategy" ? string
    "poll_timeout_ms" ? long(0..)
    "receive_buffer_bytes" ? string
    "reconnect_backoff_ms" ? string
    "request_timeout_ms" ? string
    "retry_backoff_ms" ? string
    "sasl_jaas_config" ? string
    "sasl_kerberos_service_name" ? string
    "sasl_mechanism" ? string
    "security_protocol" ? string with match(SELF, ("PLAINTEXT|SASL_PLAINTEXT|SSL|SASL_SSL"))
    "send_buffer_bytes" ? string
    "session_timeout_ms" ? string
    "ssl_endpoint_identification_algorithm" ? string
    "ssl_key_password" ? string
    "ssl_keystore_location" ? absolute_file_path
    "ssl_keystore_password" ? string
    "ssl_keystore_type" ? string
    "ssl_truststore_location" ? absolute_file_path
    "ssl_truststore_password" ? string
    "ssl_truststore_type" ? string
    "topics" ? string[] = list("logstash")
    "topics_pattern" ? string
    "value_deserializer_class" ? string
};

type logstash_input_plugin = {
    "file" ? logstash_input_file
    "gelf" ? logstash_input_gelf
    "tcp" ? logstash_input_tcp
    "udp" ? logstash_input_udp
    "lumberjack" ? logstash_input_lumberjack
    "beats" ? logstash_input_beats
    "zeromq" ? logstash_input_zeromq
    "kafka" ? logstash_input_kafka
} with length(SELF) == 1;


@{ Base for all filters }
type logstash_name_pattern = {
    "name" : string
    "pattern" : string
};

type logstash_name_patterns = {
    "name" : string
    "pattern" : string[]
};

@{A name_patternlist is rendered differently than a name_patterns}
type logstash_filter_name_patternlist = {
    "name" : string
    "pattern" : string[]
};

type logstash_filter_plugin_common = {
    include logstash_plugin_common
    "add_field" ? string{}
    "add_tag" ? string[]
    "remove_field" ? string[]
    "remove_tag" ? string[]
};

type logstash_filter_grok = {
    include logstash_filter_plugin_common
    "match" ? logstash_name_patterns[]
    "break_on_match" : boolean = true
    "drop_if_match" ? boolean
    "keep_empty_captures" ? boolean
    "named_captures_only" : boolean = true
    "patterns_dir" ? string[]
    "overwrite" ? string[]
    "tag_on_failure" ? string[]
    "tag_on_timeout" ? string[]
    "timeout_millis" ? long
    "timeout_scope" ? choice('event', 'pattern')
    "target" ? string
};

type logstash_filter_bytes2human = {
    include logstash_filter_plugin_common
    "convert" : string{}
};

type logstash_filter_date = {
    include logstash_filter_plugin_common
    "match" : logstash_filter_name_patternlist
};

type logstash_filter_grep = {
    include logstash_filter_plugin_common
    "match" ? logstash_name_pattern[]
    "drop" : boolean = true
    "negate" : boolean = false
};

type logstash_filter_drop = {
    include logstash_filter_plugin_common
    "percentage" ? long(0..100)
    "periodic_flush" ? boolean
};

type logstash_filter_mutate_convert = string with match(SELF, '^(integer|float|string|boolean)$');

type logstash_filter_mutate = {
    include logstash_filter_plugin_common
    "convert" ? logstash_filter_mutate_convert{}
    "replace" ? logstash_name_pattern[]
    "rename" ? string{}
    "split" ? string{}
    "update" ? string{}
    "strip" ? string[]
    "exclude_tags" ? string[] with {
        deprecated(0, 'replace with _conditional e.g. <"tagname" not in [tags]> in 2.0'); true;
    }
};

type logstash_filter_kv = {
    include logstash_filter_plugin_common
    "default_keys" ? string{}
    "exclude_keys" ? string[]
    "include_keys" ? string[]
    "prefix" ? string
    "source" ? string
    "target" ? string
    "trim_value" ? string
    "trim_key" ? string
    "value_split" ? string
};

type logstash_filter_json = {
    include logstash_filter_plugin_common
    "source" : string
    "target" : string
    "remove_field" ? string[]
};

type logstash_filter_geoip = {
    include logstash_filter_plugin_common
    "cache_size" ? long
    "database" ? absolute_file_path
    "default_database_type" ? choice('City', 'ASN')
    "fields" ? string[]
    "source" : string
    "tag_on_failure" ? string[]
    "target" ? string
};

type logstash_filter_plugin = {
    "grok" ? logstash_filter_grok
    "date" ? logstash_filter_date
    "grep" ? logstash_filter_grep with {
        deprecated(0, 'grep filter is removed from 2.0, use e.g. conditional drop'); true;
    }
    "drop" ? logstash_filter_drop
    "mutate" ? logstash_filter_mutate
    "kv" ? logstash_filter_kv
    "bytes2human" ? logstash_filter_bytes2human
    "json" ? logstash_filter_json
    "geoip" ? logstash_filter_geoip
} with length(SELF) == 1;

@{ Common output }
type logstash_output_codec = {
    "plain" ? logstash_codec_plain
} with length(SELF) == 1;

type logstash_output_plugin_common = {
    include logstash_plugin_common
    "codec" ? logstash_output_codec
};

@{ GELF-based output }
type logstash_output_gelf = {
    include logstash_output_plugin_common
    "host" : type_fqdn
    "level" : string[] = list("info")
    "port" : type_port = 12201
    "custom_fields" ? string{}
    "ship_metadata" : boolean = true
    "ship_tags" : boolean = true
    "facility" ? string
    "sender" ? string
};

@{ tcp-based output }
type logstash_output_tcp = {
    include logstash_output_plugin_common
    include logstash_ssl
    "ssl_cacert" ? string
    "enable_metric" ? boolean = true
    "host" : type_fqdn
    "id" ? string
    "mode" ? string = "client" with match(SELF, ("server|client"))
    "port" : long
    "reconnect_interval" ? long
    "workers" ? number = 1
};

@{ stdout-based output }
type logstash_output_stdout = {
    include logstash_output_plugin_common
    "debug" ? boolean
};

@{ elasticsearch-based output }
type logstash_output_elasticsearch = {
    include logstash_output_plugin_common
    "bulk_path" ? string
    "cacert" ? absolute_file_path
    "custom_headers" ? dict
    "doc_as_upsert" ? boolean
    "document_id" ? string
    "document_type" ? string
    "failure_type_logging_whitelist" ? string[]
    "healthcheck_path" ? string
    "hosts" ? string[]
    "http_compression" ? boolean
    "ilm_enabled" ? string with match(SELF, ("true|false|auto"))
    "ilm_pattern" ? string
    "ilm_policy" ? string
    "ilm_rollover_alias" ? string
    "index" ? string
    "keystore" ? absolute_file_path
    "keystore_password" ? string
    "manage_template" ? boolean
    "parameters" ? dict
    "parent" ? string
    "password" ? string
    "path" ? string
    "pipeline" ? string
    "pool_max" ? long(0..) = 1000
    "pool_max_per_route" ? long(0..) = 100
    "proxy" ? type_absoluteURI
    "resurrect_delay" ? long(0..)
    "retry_initial_interval" ? long(0..)
    "retry_max_interval" ? long(0..)
    "retry_on_conflict" ? long(0..)
    "routing" ? string
    "script" ? string
    "script_lang" ? string
    "script_type" ? string with match(SELF, ("inline|indexed|file"))
    "script_var_name" ? string
    "scripted_upsert" ? boolean
    "sniffing" ? boolean
    "sniffing_delay" ? long(0..)
    "sniffing_path" ? string
    "ssl" ? boolean
    "ssl_certificate_verification" ? boolean
    "template" ? absolute_file_path
    "template_name" ? string
    "template_overwrite" ? boolean
    "timeout" ? long(0..)
    "truststore" ? absolute_file_path
    "truststore_password" ? string
    "upsert" ? string
    "user" ? string
    "validate_after_inactivity" ? long(0..)
    "version" ? string
    "version_type" ? string with match(SELF, ("internal|external|external_gt|external_gte|force"))
};

@{ file based output }
type logstash_output_file = {
    "path" : absolute_file_path
};

type logstash_output_plugin = {
    "elasticsearch" ? logstash_output_elasticsearch
    "gelf" ? logstash_output_gelf
    "stdout" ? logstash_output_stdout
    "tcp" ? logstash_output_tcp
    "file" ? logstash_output_file
} with length(SELF) == 1;

type logstash_input_conditional = {
    include logstash_conditional
    "plugins" ? logstash_input_plugin[]
};

type logstash_filter_conditional = {
    include logstash_conditional
    "plugins" ? logstash_filter_plugin[]
};

type logstash_output_conditional = {
    include logstash_conditional
    "plugins" ? logstash_output_plugin[]
};

type logstash_input = {
    "plugins" ? logstash_input_plugin[]
    "conditionals" ? logstash_input_conditional[]
};

type logstash_filter = {
    "plugins" ? logstash_filter_plugin[]
    "conditionals" ? logstash_filter_conditional[]
};

type logstash_output = {
    "plugins" ? logstash_output_plugin[]
    "conditionals" ? logstash_output_conditional[]
};

@{ The configuration is made of input, filter and output section }
type type_logstash = {
    "input" : logstash_input
    "filter" ? logstash_filter
    "output" : logstash_output
};

@{ logstash-forwarder type }
type type_logstash_forwarder_network_server = {
    "host" : type_hostname
    "port" : long(0..)
};

type type_logstash_forwarder_network = {
    "servers" : type_logstash_forwarder_network_server[]
    "ssl_certificate" ? string
    "ssl_key" ? string
    "ssl_ca" ? string
    "timeout" : long(0..) = 15
};

type type_logstash_forwarder_file_fields = {
    "type" : string
};

type type_logstash_forwarder_file = {
    "paths" : string[]
    "fields" : type_logstash_forwarder_file_fields
};

type type_logstash_forwarder = {
    "network" : type_logstash_forwarder_network
    "files" : type_logstash_forwarder_file[]
};

type type_logstash_yml_node = {
    "name" ? string
};

type type_logstash_yml_pipeline = {
    "workers" ? long
    "output.workers" ? long
    "batch.size" ? long
    "unsafe_shutdown" ? boolean
};

type type_logstash_yml_path = {
    "config" ? string
    "data" ? string
    "logs" ? string
    "plugins" ? string[]
    "queue" ? string
};

type type_logstash_yml_config = {
    "string" ? string
    "test_and_exit" ? boolean
    "reload.automatic" ? boolean
    "reload.interval" ? long
    "debug" ? boolean
};

type type_logstash_yml_queue = {
    "type" ? string
    "page_capacity" ? string
    "max_events" ? long
    "max_bytes" ? long
    "checkpoint.acks" ? long
    "checkpoint.writes" ? long
    "checkpoint.interval" ? long
};

type type_logstash_yml_http = {
    "host" ? string
    "port" ? string
};

type type_logstash_yml_log = {
    "level" ? string with match(SELF, "(fatal|error|warn|info|debug|trace)")
};

type type_logstash_yml = {
    "node" ? type_logstash_yml_node
    "pipeline" ? type_logstash_yml_pipeline
    "path" ? type_logstash_yml_path
    "config" ? type_logstash_yml_config
    "queue" ? type_logstash_yml_queue
    "http" ? type_logstash_yml_http
    "log" ? type_logstash_yml_log
};

