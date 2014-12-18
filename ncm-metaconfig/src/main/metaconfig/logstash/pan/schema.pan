declaration template metaconfig/logstash/schema;

@{ Schema for logstash inputs, outputs and filters. See
http://logstash.net/docs/1.2.2/ for all the details.
}

include 'pan/types';

type logstash_port_range = long(1..)[] with length(SELF) == 2;

type logstash_ssl = {
    "ssl_cacert" ? string
    "ssl_cert" ? string
    "ssl_key" ? string
    "ssl_key_passphrase" ? string
    "ssl_enable" ? boolean
    "ssl_verify" ? boolean
};

@{ Common portion for all plugins }
type logstash_plugin_common = {
};

# list not complete at all
type logstash_codec_charset = string with match(SELF,"^(UTF-8|locale|external|filesystem|internal)$");

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
    "codec" ? logstash_input_codec
};

@{ File-based input }
type logstash_input_file = {
    include logstash_input_plugin_common
    "path" : string[]
    "exclude" ? string[]
    "sincedb_path" ? string
    "sincedb_write_interval" ? long(1..)
    "stat_interval" : long(1..) = 1
    "start_position" ? string with match(SELF,'^(beginning|end)$')
};

@{ Collecting from tcp }
type logstash_input_tcp = {
    include logstash_input_plugin_common
    include logstash_ssl
    "port" : type_port
    "host" ? type_hostname
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

type logstash_input_plugin = {
    "file" ? logstash_input_file
    "gelf" ? logstash_input_gelf
    "tcp" ? logstash_input_tcp
    "udp" ? logstash_input_udp
    "lumberjack" ? logstash_input_lumberjack
} with length(SELF) == 1;


@{ Base for all filters }
type logstash_name_pattern = {
    "name" : string
    "pattern": string
};

type logstash_filter_name_patternlist = {
    "name" : string
    "pattern": string[]
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
    "match" ? logstash_name_pattern[]
    "break_on_match" : boolean = true
    "drop_if_match" ? boolean 
    "keep_empty_captures" ? boolean
    "named_captures_only" : boolean = true
    "patterns_dir" ? string[]
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

type logstash_filter_mutate = {
    include logstash_filter_plugin_common
    "replace" ? logstash_name_pattern[]
    "rename" ? string{}
    "split" ? string{}
    "exclude_tags" ? string[] # DEPRECATED, should be replaced by conditional block
};

type logstash_filter_plugin = {
    "grok" ? logstash_filter_grok
    "date" ? logstash_filter_date
    "grep" ? logstash_filter_grep
    "mutate" ? logstash_filter_mutate
} with length(SELF) == 1;

@{ Common output }
type logstash_output_codec = {
    "plain" ? logstash_codec_plain
} with length(SELF) == 1;

type logstash_output_plugin_common = {
    include logstash_plugin_common
    "codec" ? logstash_output_codec
    "workers" ? long(1..)
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

@{ stdout-based output }
type logstash_output_stdout = {
    include logstash_output_plugin_common
    "debug" ? boolean
};

@{ elasticsearch-based output }
type logstash_output_elasticsearch = {
    include logstash_output_plugin_common
    "bind_host" ? type_hostname
    "host" ? type_hostname
    "port" ? logstash_port_range
    "cluster" ? string
    "embedded" : boolean = false
    "index" : string = "logstash-%{+YYYY.MM.dd}"
    "flush_size" : long = 5000
    "index_type" : string = "%{@type}"
};

type logstash_output_plugin = {
    "gelf" ? logstash_output_gelf
    "stdout" ? logstash_output_stdout
    "elasticsearch" ? logstash_output_elasticsearch
} with length(SELF) == 1;

type logstash_conditional_expression = {
    # [join] [[left] test] right (eg: and left > right; ! right;)
    "join" ? string with match(SELF,'^(and|or|nand|xor)$')
    "left" : string
    "test" ? string with match(SELF,'^(==|!=|<|>|<=|>=|=~|!~|in|not in|!)$')
    "right" ? string
};

# no nesting (yet)
type logstash_conditional = {
    # ifelseif: first one is 'if', rest is 'if else'
    # ifelseifelse: first one is 'if', last is 'else', rest is 'if else'
    "type" : string with match(SELF, '^(if|if else|else|ifelseif|ifelseifelse)$')
    "expr" : logstash_conditional_expression[]
};

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
