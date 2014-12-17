object template server;

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
        nlist("date", nlist(
            "match", nlist(
                "name", "syslog_timestamp", 
                "pattern", list("yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZ", "yyyy-MM-dd'T'HH:mm:ssZZ"),
                ),
            )),
        nlist("mutate", nlist(
            "exclude_tags", list("_grokparsefailure"),
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
    ),
));

# reset the output, to remove the GELF output
"output" = nlist("plugins", list(nlist(
    "elasticsearch", nlist(
        "flush_size", 5000,
        "bind_host", "localhost",
        "workers", 4,
        "port", list(9300,9305), 
        ),
)));

