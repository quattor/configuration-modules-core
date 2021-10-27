# This is a metaconfig schema for filebeat version 7.0+ only.
declaration template metaconfig/beats/schema_7.0;

include 'pan/types';

type beats_output_logstash_ssl_protocol = string with match(SELF, '^(SSLvs|TLSv1.0|TLSv1.1|TLSv1.2)');

@documentation{
    SSL settings for logstash output
}
type beats_output_logstash_ssl = {
    'certificate_authorities' ? absolute_file_path[]
    'certificate' ? absolute_file_path
    'key' ? absolute_file_path
    'key_passphrase' ? string_trimmed
    'insecure' ? boolean
    'cipher_suites' ? string_trimmed[]
    'curve_types' ? string_trimmed[]
    'verification_mode' ? choice('none', 'full', 'certificate')
    'supported_protocols' ? beats_output_logstash_ssl_protocol[]
    'enabled' ? boolean
};

@documentation{
    TLS settings for elasticsearch output
}
type beats_output_elasticsearch_ssl = {
    include beats_output_logstash_ssl
};

@documentation {
    TLS settings for kafka output
}
type beats_output_kafka_ssl = {
    include beats_output_logstash_ssl
};

@documentation {
    kafka as output
}
type beats_output_kafka = {
    'hosts' ? type_hostport []
    'username' ? string_trimmed
    'password' ? string_trimmed
    'topic' ? string_trimmed
    'ssl' ? beats_output_kafka_ssl
    'version' ? string_trimmed
};

@documentation{
    elasticsearch as output
}
type beats_output_elasticsearch = {
    'hosts' ? type_hostport[]
    'protocol' ? string with match(SELF, '^https?$')
    'username' ? string_trimmed
    'password' ? string_trimmed
    'worker' ? long(0..)
    'index' ? string_trimmed
    'path' ? absolute_file_path
    'proxy_url' ? type_URI
    'max_retries' ? long(0..)
    'bulk_max_size' ? long(0..)
    'timeout' ? long(0..)
    'flush_interval' ? long(0..)
    'save_topology' ? boolean
    'topology_expire' ? long(0..)
    'ssl' ? beats_output_elasticsearch_ssl
};

@documentation{
    logstash as output
}
type beats_output_logstash = {
    'hosts' ? type_hostport[]
    'compression_level' ? long(0..9)
    'worker' ? long(0..)
    'loadbalance' ? boolean
    'pipelining' ? long(0..)
    'proxy_url' ? type_URI
    'proxy_use_local_resolver' ? boolean
    'index' ? string_trimmed
    'ssl' ? beats_output_logstash_ssl
    'timeout' ? long(0..)
    'max_retries' ? long
    'bulk_max_size' ? long
};

@documentation{
    file(s) as output
}
type beats_output_file = {
    'path' ? absolute_file_path
    'filename' ? absolute_file_path
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
    'kafka' ? beats_output_kafka
    'file' ? beats_output_file
    'console' ? beats_output_console
} with {
    length(SELF) >= 1 || error('At least one beat output must be specified');
};


@documentation{
    shipper geoip
}
type beats_shipper_geoip = {
    'paths' ? absolute_file_path[]
};

@documentation{
    Enable debug output for the a (or all) component(s).
}
type beats_logging_selector = string with match(SELF, '^(beat|publish|service|\*)$');

@documentation{
    log to local files
}
type beats_logging_files = {
    'path' ? absolute_file_path
    'name' ? string_trimmed
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
    'level' ? choice('critical', 'error', 'warning', 'info', 'debug')
};

@documenation{
    Shared components for each beats service
}
type beats_service = {
    'output' : beats_output
    'logging' ? beats_logging
    'name' ? string_trimmed
    'tags' ? string_trimmed[]
    'ignore_outgoing' ? boolean
    'refresh_topology_freq' ? long(0..)
    'topology_expire' ? long(0..)
    'geoip' ? beats_shipper_geoip
    'seccomp.enabled' ? boolean
};

@documentation{
    Handle logmessages spread over multiple lines
}
type beats_filebeat_input_multiline = {
    'pattern' ? string_trimmed
    'negate' ? boolean
    'match' ? choice('after', 'before')
    'max_lines' ? long(0..)
    'timeout' ? long(0..)
};

@documentation{
    Configure a input (source of certain class of data, can come multiple paths)
}
type beats_filebeat_input = {
    'paths' : absolute_file_path[]
    'encoding' ? choice(
        'big5',
        'euc-jp',
        'euc-kr',
        'gb18030',
        'gbk',
        'hz-gb-2312',
        'iso-2022-jp',
        'plain',
        'shift-jis',
        'utf-16be',
        'utf-16be-bom',
        'utf-16le',
        'utf-8',
    )
    'type' ? choice('log', 'stdin')
    'exclude_lines' ? string_trimmed[]
    'include_lines' ? string_trimmed[]
    'exclude_files' ? absolute_file_path[]
    'fields' ? string_trimmed{}
    'fields_under_root' ? boolean
    'ignore_older' ? long(0..)
    'scan_frequency' ? long(0..)
    'harvester_buffer_size' ? long(0..)
    'max_bytes' ? long(0..)
    'multiline' ? beats_filebeat_input_multiline
    'tail_files' ? boolean
    'backoff' ? long(0..)
    'max_backoff' ? long(0..)
    'backoff_factor' ? long(0..)
    'enabled' ? boolean
};

@documentation{
    Filebeat configuration
}
type beats_filebeat_filebeat = {
    'inputs' : beats_filebeat_input[]
    'prospectors' : beats_filebeat_input[]
    'registry_file' ? absolute_file_path
    'config_dir' ? absolute_file_path
};

@documentation{
    Filebeat service
    (see https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-configuration-details.html)
}
type beats_filebeat_service = {
    include beats_service
    'filebeat' : beats_filebeat_filebeat
};

@documentation {
    Gpfsbeat configuration

    devices: the filesystems as named in GPFS
    mmrequota, mmlsfs, mmlsfilset, mmdf: paths to these executables
}
type beats_gpfsbeat_gpfsbeat = {
    'period' : string_trimmed # is of the form 42s
    'devices' : string_trimmed[]
    'mmrepquota' ? absolute_file_path
    'mmlsfs' ? absolute_file_path
    'mmlsfileset' ? absolute_file_path
    'mmdf' ? absolute_file_path
};

@documentation {
    Gpfsbeat service
}
type beats_gpfsbeat_service = {
    include beats_service
    'gpfsbeat': beats_gpfsbeat_gpfsbeat
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
    'procs' ? string_trimmed[]
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
