declaration template metaconfig/beats/schema;

include 'pan/types';

@documentation{
    TLS settings for logstash output
}
type beats_output_logstash_tls = {
    'certificate_authorities' ? string[]
    'certificate' ? string
    'certificate_key' ? string
    'insecure' ? boolean
    'cipher_suites' ? string[]
    'curve_types' ? string[]
};

@documentation{
    TLS settings for elasticsearch output
}
type beats_output_elasticsearch_tls = {
    include beats_output_logstash_tls
    'min_version' ? string with match(SELF, '^\d+(\.\d+)+?$')
    'max_version' ? string with match(SELF, '^\d+(\.\d+)+?$')
};

@documentation{
    elasticsearch as output
}
type beats_output_elasticsearch = {
    'hosts' ? type_hostport[]
    'protocol' ? string with match(SELF, '^https?$')
    'username' ? string
    'password' ? string
    'worker' ? long(0..)
    'index' ? string
    'path' ? string
    'proxy_url' ? string
    'max_retries' ? long(0..)
    'bulk_max_size' ? long(0..)
    'timeout' ? long(0..)
    'flush_interval' ? long(0..)
    'save_topology' ? boolean
    'topology_expire' ? long(0..)
    'tls' ? beats_output_elasticsearch_tls
};

@documentation{
    logstash as output
}
type beats_output_logstash = {
    'hosts' ? type_hostport[]
    'worker' ? long(0..)
    'loadbalance' ? boolean
    'index' ? string
    'tls' ? beats_output_logstash_tls
};

@documentation{
    file(s) as output
}
type beats_output_file = {
    'path' ? string
    'filename' ? string
    'rotate_every_kb' ? long(0..)
    'number_of_files' ? long(0..)
};

@documentation{
    console as output
}
type beats_output_console = {
    'pretty' ? boolean
};

@documentation{
    Configure output (only one can be configured)
}
type beats_output = {
    'elasticsearch' ? beats_output_elasticsearch
    'logstash' ? beats_output_logstash
    'file' ? beats_output_file
    'console' ? beats_output_console
} with {
    length(SELF) >= 1 || error('At least one beat output must be specified');
};


@documentation{
    shipper geoip
}
type beats_shipper_geoip = {
    'paths' ? string[]
};

@documentation{
    The shipper publishes the data
}
type beats_shipper = {
    'name' ? string
    'tags' ? string[]
    'ignore_outgoing' ? boolean
    'refresh_topology_freq' ? long(0..)
    'topology_expire' ? long(0..)
    'geoip' ? beats_shipper_geoip
};

@documentation{
    Enable debug output for the a (or all) component(s).
}
type beats_logging_selector = string with match(SELF, '^(beat|publish|service|\*)$');

@documentation{
    log to local files
}
type beats_logging_files = {
    'path' ? string
    'name' ? string
    'rotateeverybytes' ? long(0..)
    'keepfiles' ? long(0..)
};

@documentation{
    Configure logging of beats itself.
}
type beats_logging = {
    'to_syslog' ? boolean
    'to_files' ? boolean
    'files' ? beats_logging_files
    'selectors' ? beats_logging_selector[]
    'level' ? string with match(SELF, '^(critical|error|warning|info|debug)$')
};

@documenation{
    Shared components for each beats service
}
type beats_service = {
    'output' : beats_output
    'shipper' ? beats_shipper
    'logging' ? beats_logging
};

@documentation{
    Handle logmessages spread over multiple lines
}
type beats_filebeat_prospector_multiline = {
    'pattern' ? string
    'negate' ? boolean
    'match' ? string with match(SELF, '^(after|before)$')
    'max_lines' ? long(0..)
    'timeout' ? long(0..)
};

@documentation{
    Configure a prospector (source of certain class of data, can come multiple paths)
}
type beats_filebeat_prospector = {
    'paths' : string[]
    'encoding' ? string with match(SELF, '^(plain|utf-8|utf-16be-bom|utf-16be|utf-16le|big5|gb18030|gbk|hz-gb-2312|euc-kr|euc-jp|iso-2022-jp|shift-jis)$')
    'input_type' ? string with match(SELF, '^(log|stdin)$')
    'exclude_lines' ? string[]
    'include_lines' ? string[]
    'exclude_files' ? string[]
    'fields' ? string{}
    'fields_under_root' ? boolean
    'ignore_older' ? long(0..)
    'document_type' ? string
    'scan_frequency' ? long(0..)
    'harvester_buffer_size' ? long(0..)
    'max_bytes' ? long(0..)
    'multiline' ? beats_filebeat_prospector_multiline
    'tail_files' ? boolean
    'backoff' ? long(0..)
    'max_backoff' ? long(0..)
    'backoff_factor' ? long(0..)
    'force_close_files' ? boolean
};

@documentation{
    Filebeat configuration
}
type beats_filebeat_filebeat = {
    'prospectors' : beats_filebeat_prospector[]
    'spool_size' ? long(0..)
    'idle_timeout' ? long(0..)
    'registry_file' ? string
    'config_dir' ? string
};

@documentation{
    Filebeat service
    (see https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-configuration-details.html)
}
type beats_filebeat_service = {
    include beats_service
    'filebeat' : beats_filebeat_filebeat
};

@documentation{
    Topbeat input source(s)
}
type beats_topbeat_input_stats = {
    'system' ? boolean
    'proc' ? boolean
    'filesystem' ? boolean
    'cpu_per_core' ? boolean
};

@documentation{
    Topbeat configuration
}
type beats_topbeat_input = {
    'period' : long(0..) = 10
    'procs' ? string[]
    'stats' ? beats_topbeat_input_stats
};

@documentation{
    Topbeat service
    (see https://www.elastic.co/guide/en/beats/topbeat/current/topbeat-configuration-options.html)
}
type beats_topbeat_service = {
    include beats_service
    'input' : beats_topbeat_input
};
