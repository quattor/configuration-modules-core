object template server;

variable METACONFIG_LOGSTASH_VERSION = '2.0';

include 'metaconfig/logstash/config';

prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents";

"input/plugins" = append(dict("tcp", dict(
    "type", "syslog",
    "port", 514,
)));

# gelf input
"input/plugins" = append(dict("gelf", dict(
    # type is/can be set in output gelf filter.
    # this will not forcefully overwrtie in 1.2.2
    "type", "remotegelf",
    "port", 12201,
)));

"input/plugins" = append(dict("lumberjack", dict(
    "type", "lumberjack",
    "port", 5043,
    "ssl_certificate", "/software/components/ccm/cert_file",
    "ssl_key", "/software/components/ccm/key_file",
)));

"input/plugins" = append(dict("beats", dict(
    "type", "beats",
    "port", 5043,
    "ssl_certificate", "/software/components/ccm/cert_file",
    "ssl_key", "/software/components/ccm/key_file",
    "ssl", true,
    "congestion_threshold", 20,
)));

"filter/conditionals" = append(dict(
    "type", "ifelseif",
    "expr", list(dict(
        "left", "[type]",
        "test", "==",
        "right", "'remotegelf'",
        )),
    "plugins", list(dict("mutate", dict(
        "split", dict("tags", ", "),
    ))),
));

"filter/conditionals" = append(dict(
    "type", "ifelseif",
    "expr", list(dict(
        "left", "[type]",
        "test", "==",
        "right", "'syslog'",
        )),
    "plugins", list(
        dict("grok", dict(
            "match", list(dict(
                "name", "message",
                "pattern", list("%{RSYSLOGCUSTOM}", "%{OTHERPATTERN}"),
                )),
            "patterns_dir", list("/usr/share/grok"),
            "add_field", dict(
                "received_at", "%{@timestamp}",
                "received_from", "%{@source_host}",
                ),
            )),
        dict("kv", dict(
            "default_keys", dict(
                "key1", "value1",
                "key2", "value2",
                ),
            "exclude_keys", list("key1e", "key2e"),
            "include_keys", list("key1i", "key2i"),
            "prefix", "myprefix",
            "source", "mysource",
            "target", "mytarget",
            "trim", "mytrim",
            "trimkey", "mytrimkey",
            "value_split", "myvaluesplit",
            )),
        dict("date", dict(
            "match", dict(
                "name", "syslog_timestamp",
                "pattern", list("yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZ", "yyyy-MM-dd'T'HH:mm:ssZZ"),
                ),
            )),
        dict("mutate", dict(
            "_conditional", dict('expr', list(dict(
                "left", "'_grokparsefailure'",
                "test", "not in",
                "right", "[tags]",
                ))),
            "replace", list(
                dict(
                    "name", "@source_host",
                    "pattern", "%{syslog_hostname}"),
                dict(
                    "name", "@message",
                    "pattern", "%{syslog_message}"),
                ),
            )),
        dict("mutate", dict(
            "remove_field", list("syslog_hostname", "syslog_message", "syslog_timestamp"),
            )),
        dict("mutate", dict(
            "_conditional", dict('expr', list(
                dict(
                    "left", "'_grokparsefailure'",
                    "test", "not in",
                    "right", "[tags]",
                ),
                dict(
                    "join", "and",
                    "left", "[jube_id]",
                ))),
            "convert", dict(
                "success", "boolean"
                ),
            )),
        dict("mutate", dict(
            "add_field", dict(
                escape("[@metadata][target_index]"), "longterm-%{+YYYY.MM.dd}",
                ),
            )),
        dict("mutate", dict(
            "_conditional", dict("expr", list(dict(
                "left", "[program]",
                "test", "==",
                "right", "\"jube\"",
                ))),
            "update", dict(
                escape("[@metadata][target_index]"), "longterm-%{+YYYY.Q}",
                ),
            )),
        dict("bytes2human", dict(
            "convert", dict(
                "field1", "bytes",
                "field2", "bytes",
                ),
            )),
    ),
));

# reset the output, to remove the GELF output
"output" = dict("plugins", list(dict(
    "elasticsearch", dict(
        "flush_size", 5000,
        "hosts", list("localhost.localdomain:9200"),
        "workers", 4,
        "template_overwrite", true,
        ),
)));
