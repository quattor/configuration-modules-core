declaration template metaconfig/logstash/schema_2.0;

@{ Schema for logstash inputs, outputs and filters. See
https://www.elastic.co/guide/en/logstash/2.0/index.html for all the details.
}

include 'pan/types';

type logstash_20_port_range = long(1..)[] with length(SELF) == 2;

type logstash_20_ssl = {
    "ssl_cacert" ? string
    "ssl_cert" ? string
    "ssl_key" ? string
    "ssl_key_passphrase" ? string
    "ssl_enable" ? boolean
    "ssl_verify" ? boolean
};

type logstash_20_conditional_expression = {
    # [join] [[left] test] right (eg: and left > right; ! right;)
    "join" ? string with match(SELF, '^(and|or|nand|xor)$')
    "left" : string
    "test" ? string with match(SELF, '^(==|!=|<|>|<=|>=|=~|!~|in|not in|!)$')
    "right" ? string
};

# no nesting (yet)
type logstash_20_conditional = {
    # ifelseif: first one is 'if', rest is 'if else'
    # ifelseifelse: first one is 'if', last is 'else', rest is 'if else'
    "type" : string = 'if' with match(SELF, '^(if|if else|else|ifelseif|ifelseifelse)$')
    "expr" : logstash_20_conditional_expression[]
};

@{ Common portion for all plugins }
type logstash_20_plugin_common = {
    @{using _conditional to avoid name clash with plugin option name.
      The conditional is only for the single plugin and has to be type 'if' (the default).}
    "_conditional" ? logstash_20_conditional with { if (SELF['type'] != 'if') {
        error('plugin _conditional has to be type if (the default)'); }; true;
    }
};

# list not complete at all
type logstash_20_codec_charset = string with match(SELF, "^(UTF-8|locale|external|filesystem|internal)$");

type logstash_20_codec_common = {
    # there are codecs without any values to set. this should stay empty?
};

type logstash_20_codec_plain = {
    include logstash_20_codec_common
    "charset" ? logstash_20_codec_charset
    "format" ? string
};

type logstash_20_codec_json = {
    include logstash_20_codec_common
    "charset" ? logstash_20_codec_charset
};

type logstash_20_input_codec = {
    "json" ? logstash_20_codec_json
    "plain" ? logstash_20_codec_plain
} with length(SELF) == 1;

@{ Common portion for all input plugins }
type logstash_20_input_plugin_common = {
    include logstash_20_plugin_common
    "type" : string
    "debug" ? boolean
    "tags" ? string[]
    "add_field" ? string{}
    "codec" ? logstash_20_input_codec
};

@{ File-based input }
type logstash_20_input_file = {
    include logstash_20_input_plugin_common
    "path" : string[]
    "exclude" ? string[]
    "sincedb_path" ? string
    "sincedb_write_interval" ? long(1..)
    "stat_interval" : long(1..) = 1
    "start_position" ? string with match(SELF, '^(beginning|end)$')
};

@{ Collecting from tcp }
type logstash_20_input_tcp = {
    include logstash_20_input_plugin_common
    include logstash_20_ssl
    "port" : type_port
    "host" ? type_hostname
};

@{ Collecting from udp }
type logstash_20_input_udp = {
    include logstash_20_input_plugin_common
    include logstash_20_ssl
    "port" : type_port
    "host" ? type_hostname
};

@{ GELF input }
type logstash_20_input_gelf = {
    include logstash_20_input_plugin_common
    "port" : type_port = 12201
    "host" ? type_hostname
    "remap" : boolean = true
};

@{ Lumberjack/logstash-forwarder input }
type logstash_20_input_lumberjack = {
    include logstash_20_input_plugin_common
    "port" : type_port = 12201
    "host" ? type_hostname
    "ssl_certificate" : string
    "ssl_key" : string
    "ssl_key_passphrase" ? string
};

@{ beats input }
type logstash_20_input_beats = {
    include logstash_20_input_lumberjack
    'ssl' ? boolean
    'congestion_threshold' ? long(0..)
};

type logstash_20_input_plugin = {
    "file" ? logstash_20_input_file
    "gelf" ? logstash_20_input_gelf
    "tcp" ? logstash_20_input_tcp
    "udp" ? logstash_20_input_udp
    "lumberjack" ? logstash_20_input_lumberjack
    "beats" ? logstash_20_input_beats
} with length(SELF) == 1;


@{ Base for all filters }
type logstash_20_name_pattern = {
    "name" : string
    "pattern" : string
};

type logstash_20_name_patterns = {
    "name" : string
    "pattern" : string[]
};

@{A name_patterdict is rendered differently than a name_patterns}
type logstash_20_filter_name_patterdict = {
    "name" : string
    "pattern" : string[]
};

type logstash_20_filter_plugin_common = {
    include logstash_20_plugin_common
    "add_field" ? string{}
    "add_tag" ? string[]
    "remove_field" ? string[]
    "remove_tag" ? string[]
};

type logstash_20_filter_grok = {
    include logstash_20_filter_plugin_common
    "match" ? logstash_20_name_patterns[]
    "break_on_match" : boolean = true
    "drop_if_match" ? boolean
    "keep_empty_captures" ? boolean
    "named_captures_only" : boolean = true
    "patterns_dir" ? string[]
};

type logstash_20_filter_bytes2human = {
    include logstash_20_filter_plugin_common
    "convert" : string{}
};

type logstash_20_filter_date = {
    include logstash_20_filter_plugin_common
    "match" : logstash_20_filter_name_patterdict
};

type logstash_20_filter_grep = {
    include logstash_20_filter_plugin_common
    "match" ? logstash_20_name_pattern[]
    "drop" : boolean = true
    "negate" : boolean = false
};

type logstash_20_filter_drop = {
    include logstash_20_filter_plugin_common
    "percentage" ? long(0..100)
    "periodic_flush" ? boolean
};

type logstash_20_filter_mutate_convert = string with match(SELF, '^(integer|float|string|boolean)$');

type logstash_20_filter_mutate = {
    include logstash_20_filter_plugin_common
    "convert" ? logstash_20_filter_mutate_convert{}
    "replace" ? logstash_20_name_pattern[]
    "rename" ? string{}
    "split" ? string{}
    "update" ? string{}
    "exclude_tags" ? string[] with {
        deprecated(0, 'replace with _conditional e.g. <"tagname" not in [tags]> in 2.0'); true;
    }
};

type logstash_20_filter_kv = {
    include logstash_20_filter_plugin_common
    "default_keys" ? string{}
    "exclude_keys" ? string[]
    "include_keys" ? string[]
    "prefix" ? string
    "source" ? string
    "target" ? string
    "trim" ? string
    "trimkey" ? string
    "value_split" ? string
};

type logstash_20_filter_plugin = {
    "grok" ? logstash_20_filter_grok
    "date" ? logstash_20_filter_date
    "grep" ? logstash_20_filter_grep with {
        deprecated(0, 'grep filter is removed from 2.0, use e.g. conditional drop'); true;
    }
    "drop" ? logstash_20_filter_drop
    "mutate" ? logstash_20_filter_mutate
    "kv" ? logstash_20_filter_kv
    "bytes2human" ? logstash_20_filter_bytes2human
} with length(SELF) == 1;

@{ Common output }
type logstash_20_output_codec = {
    "plain" ? logstash_20_codec_plain
} with length(SELF) == 1;

type logstash_20_output_plugin_common = {
    include logstash_20_plugin_common
    "codec" ? logstash_20_output_codec
    "workers" ? long(1..)
};

@{ GELF-based output }
type logstash_20_output_gelf = {
    include logstash_20_output_plugin_common
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
type logstash_20_output_stdout = {
    include logstash_20_output_plugin_common
    "debug" ? boolean
};

@{ elasticsearch-based output }
type logstash_20_output_elasticsearch = {
    include logstash_20_output_plugin_common
    "bind_host" ? type_hostname
    "hosts" ? type_hostport[]
    "host" ? type_hostname with {deprecated(0, 'removed in version 2.0 (use hosts instead)'); true; }
    "port" ? logstash_20_port_range with {deprecated(0, 'removed in version 2.0 (use hosts instead)'); true; }
    "cluster" ? string with {deprecated(0, 'removed in version 2.0'); true; }
    "embedded" ? boolean = false with {deprecated(0, 'removed in version 2.0'); true; }
    "index" : string = "logstash-%{+YYYY.MM.dd}"
    "flush_size" : long = 5000
    "index_type" ? string = "%{@type}" with {deprecated(0, 'renamed to document_type in version 2.0'); true; }
    "document_type" : string = "%{@type}"
    "template_overwrite" ? boolean
};

type logstash_20_output_plugin = {
    "gelf" ? logstash_20_output_gelf
    "stdout" ? logstash_20_output_stdout
    "elasticsearch" ? logstash_20_output_elasticsearch
} with length(SELF) == 1;

type logstash_20_input_conditional = {
    include logstash_20_conditional
    "plugins" ? logstash_20_input_plugin[]
};

type logstash_20_filter_conditional = {
    include logstash_20_conditional
    "plugins" ? logstash_20_filter_plugin[]
};

type logstash_20_output_conditional = {
    include logstash_20_conditional
    "plugins" ? logstash_20_output_plugin[]
};

type logstash_20_input = {
    "plugins" ? logstash_20_input_plugin[]
    "conditionals" ? logstash_20_input_conditional[]
};

type logstash_20_filter = {
    "plugins" ? logstash_20_filter_plugin[]
    "conditionals" ? logstash_20_filter_conditional[]
};

type logstash_20_output = {
    "plugins" ? logstash_20_output_plugin[]
    "conditionals" ? logstash_20_output_conditional[]
};

@{ The configuration is made of input, filter and output section }
type type_logstash_20 = {
    "input" : logstash_20_input
    "filter" ? logstash_20_filter
    "output" : logstash_20_output
};

@{ logstash-forwarder type }
type type_logstash_20_forwarder_network_server = {
    "host" : type_hostname
    "port" : long(0..)
};

type type_logstash_20_forwarder_network = {
    "servers" : type_logstash_20_forwarder_network_server[]
    "ssl_certificate" ? string
    "ssl_key" ? string
    "ssl_ca" ? string
    "timeout" : long(0..) = 15
};

type type_logstash_20_forwarder_file_fields = {
    "type" : string
};

type type_logstash_20_forwarder_file = {
    "paths" : string[]
    "fields" : type_logstash_20_forwarder_file_fields
};

type type_logstash_20_forwarder = {
    "network" : type_logstash_20_forwarder_network
    "files" : type_logstash_20_forwarder_file[]
};
