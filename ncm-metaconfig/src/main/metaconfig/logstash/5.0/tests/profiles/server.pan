object template server;

variable METACONFIG_LOGSTASH_VERSION ?= '5.0';
variable SYSLOG_RELAY_PORT ?= 5678;
variable BEAT_RELAY_PORT ?= 26001;
variable CERT_PKCS8_PASSPHRASE ?= 'DUMMY';

include 'metaconfig/logstash/config';

variable SYSLOG_GROK_PATTERNS ?= {
    # keep this list in sync with logstash-patterns rpm
    patterns = list('ssh', 'modulecmd', 'lmod', 'nfs', 'ceph', 'opennebula', 'jube', 'keyvalue', 'quattor', 'snoopy');
    foreach(idx; pattern; patterns) {
        append(format('%%{RSYSLOGPREFIX}%%{%s_MSG}', to_uppercase(pattern)));
    };
    # always last
    append("%{RSYSLOGCUSTOM}");
    SELF;
};

prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents";

"input/plugins" = append(dict("tcp", dict(
    "type", "syslog",
    "port", SYSLOG_RELAY_PORT,
)));

"input/plugins" = append(dict("tcp", dict(
    "type", "beat",
    "port", BEAT_RELAY_PORT,
    "mode", "server",
    "ssl_extra_chain_certs", list("/etc/pki/CA/certs/terena-bundle.pem"),
    "ssl_cert", "/etc/pki/tls/certs/logstash_cert.pem",
    "ssl_enable", true,
    "ssl_key", "/etc/pki/tls/private/logstash_cert_pkcs8.key",
    "ssl_key_passphrase", CERT_PKCS8_PASSPHRASE,
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
                "pattern", SYSLOG_GROK_PATTERNS,
                )),
            "patterns_dir", list("/usr/share/grok"),
            "add_field", dict(
                "received_at", "%{@timestamp}",
                "received_from", "%{@source_host}",
                ),
            )),
        dict("kv", dict(
            "source", "KEY_EQ_VALUEDATA",
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
                    "success", "boolean",
                )
            ),
        ),
        dict("mutate", dict(
            "remove_field", list("syslog_hostname", "syslog_message", "syslog_timestamp"),
            )),
        dict("bytes2human", dict(
            "convert", dict(
                "volumedata", "bytes",
                "volumeused", "bytes",
                "volumeavail", "bytes",
                "volumetotal", "bytes",
                "objrecovthr", "bytes",
                "actwrite", "bytes",
                "actread", "bytes",
                ),
            )),
        dict("mutate", dict(
            "_conditional", dict("expr", list(dict(
                "left", "[program]",
                "test", "==",
                "right", "\"jube\"",
                ))),
            "update", dict(escape("[@metadata][target_index]"), "longterm-%{+YYYY}"),
            )),
        ),
    )
);

"filter/plugins" = append(dict(
        "mutate", dict(
            "add_field", dict(
                escape("[@metadata][target_index]"), "logstash-%{+YYYY.MM.dd}"
            ),
        )));


"filter/conditionals" = append(dict(
    "type", "ifelseif",
    "expr", list(dict(
        "left", "[program]",
        "test", "==",
        "right", "'gpfsbeat'",
        )),
    "plugins", list(
        dict("mutate", dict(
            "update", dict(escape("[@metadata][target_index]"), "longterm-%{+YYYY}"),
        )),
    ),
    ));

# reset the output, to remove the GELF output
"output" = dict("plugins", list(dict(
    "elasticsearch", dict(
        "flush_size", 5000,
        "hosts", list("localhost:9200"),
        "template_overwrite", true,
        "index", "%{[@metadata][target_index]}",
        ),
)));


