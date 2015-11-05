object template server;

final variable METACONFIG_LOGSTASH_VERSION = '2.0';

include 'metaconfig/logstash/config';

prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents";

"input/plugins" = append(nlist("tcp", nlist(
    "type", "syslog",
    "port", 514,
)));

# gelf input
"input/plugins" = append(nlist("gelf", nlist(
    # type is/can be set in output gelf filter. 
    # this will not forcefully overwrtie in 1.2.2
    "type", "remotegelf",
    "port", 12201,
)));

"input/plugins" = append(nlist("lumberjack", nlist(
    "type", "lumberjack",
    "port", 5043,
    "ssl_certificate", "/software/components/ccm/cert_file",
    "ssl_key", "/software/components/ccm/key_file",
)));
    
    
"filter/conditionals" = append(nlist(
    "type", "ifelseif",
    "expr", list(nlist(
        "left", "[type]",
        "test", "==",
        "right", "'remotegelf'",
        )),
    "plugins", list(nlist("mutate", nlist(
        "split", nlist("tags", ", "),
    ))),
));

"filter/conditionals" = append(nlist(
    "type", "ifelseif",
    "expr", list(nlist(
        "left", "[type]",
        "test", "==",
        "right", "'syslog'",
        )),
    "plugins", list(
        nlist("grok", nlist(
            "match", list(nlist(
                "name", "message", 
                "pattern", "%{RSYSLOGCUSTOM}"
                )),
            "patterns_dir", list("/usr/share/grok"),
            "add_field", nlist(
                "received_at", "%{@timestamp}",
                "received_from", "%{@source_host}",
                ),
            )),
        nlist("kv", nlist(
            "default_keys", nlist(
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
        nlist("date", nlist(
            "match", nlist(
                "name", "syslog_timestamp", 
                "pattern", list("yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZ", "yyyy-MM-dd'T'HH:mm:ssZZ"),
                ),
            )),
        nlist("mutate", nlist(
            "_conditional", nlist('expr', list(nlist(
                "left","'_grokparsefailure'",
                "test", "not in",
                "right", "[tags]",
                ))),
            "replace", list(
                nlist(
                    "name", "@source_host", 
                    "pattern", "%{syslog_hostname}"),
                nlist(
                    "name", "@message", 
                    "pattern", "%{syslog_message}"),
                ),
            )),
        nlist("mutate", nlist(
            "remove_field", list("syslog_hostname", "syslog_message", "syslog_timestamp"),
            )),
        nlist("bytes2human", nlist(
            "convert", nlist(
                "field1", "bytes",
                "field2", "bytes",
                ),
            )),
    ),
));

# reset the output, to remove the GELF output
"output" = nlist("plugins", list(nlist(
    "elasticsearch", nlist(
        "flush_size", 5000,
        "hosts", list("localhost.localdomain:9200"),
        "workers", 4,
        ),
)));

