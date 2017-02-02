object template config;

variable METACONFIG_LOGSTASH_VERSION = '1.2';
include 'metaconfig/logstash/config';

prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents/output";

"plugins" = append(dict(
    "gelf", dict(
        "custom_fields", dict("type", "remotegelf"),
        "host", "remotehost.domain",
        "sender", "myhost.domain",
        ),
    ),
);

"conditionals" = append(dict(
    "type", "ifelseif",
    "expr", list(dict(
        "left", "[type]",
        "test", "==",
        "right", "'httpd'",
        )),
    "plugins", list(dict("gelf", dict(
        "port", 12201,
        "sender", 'myhost.domain',
        "ship_metadata", true,
        "host", 'remotehost.domain',
        "custom_fields", dict("type", "remotegelf"),
        "level", list("info"),
        ))),
));

"conditionals" = append(dict(
    "type", "ifelseif",
    "expr", list(dict(
        "left", "[type]",
        "test", "==",
        "right", "'remotegelf'",
        )),
    "plugins", list(dict("gelf", dict(
        "port", 12201,
        "ship_metadata", true,
        "host", 'remotehost.domain',
        "custom_fields", dict("type", "remotegelf"),
        "level", list("%{level}"),
        "facility", "%{facility}",
        ))),
));


prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents/input";
"plugins" = append(dict("gelf", dict(
    # type is/can be set in output gelf filter.
    # this will not forcefully overwrtie in 1.2.2
    "type", "remotegelf",
    "port", 12201,
)));


"plugins" = append(dict("file", dict(
    "path", list("/var/adm/ras/mmfs.log.latest"),
    "type", "gpfs",
    "tags", list("gpfs", "storage"),
)));

prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents/filter";
"conditionals" = append(dict(
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


"conditionals" = append(dict(
    "type", "ifelseif",
    "expr", list(dict(
        "left", "[type]",
        "test", "==",
        "right", "'gpfs'",
        )),
    "plugins", list(
        dict("grok", dict(
            "match", list(dict(
                "name", "message",
                "pattern", list("%{GPFSLOG}"),
                )),
            "patterns_dir", list("/usr/share/grok"),
            "add_field", dict("program", "gpfs"),
            )),
        dict("date", dict(
            "match", dict(
                "name", "timestamp",
                "pattern", list("E MMM dd HH:mm:ss.SSS yyyy", "E MMM  d HH:mm:ss.SSS yyyy"),
                ),
            )),
        ),
));
