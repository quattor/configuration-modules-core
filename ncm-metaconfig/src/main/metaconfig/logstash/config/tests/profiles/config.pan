object template config;

include 'metaconfig/logstash/config';

prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents/output";

"plugins" = append(nlist(
    "gelf", nlist(
        "custom_fields", nlist("type", "remotegelf"),
        "host", "remotehost.domain",
        "sender", "myhost.domain",
        ),
    ),
);

"conditionals" = append(nlist(
    "type", "ifelseif",
    "expr", list(nlist(
        "left", "[type]",
        "test", "==",
        "right", "'httpd'",
        )),
    "plugins", list(nlist("gelf", nlist(
        "port", 12201,
        "sender", 'myhost.domain',
        "ship_metadata", true,
        "host", 'remotehost.domain',
        "custom_fields", nlist("type", "remotegelf"),
        "level", list("info"),
        ))),
));

"conditionals" = append(nlist(
    "type", "ifelseif",
    "expr", list(nlist(
        "left", "[type]",
        "test", "==",
        "right", "'remotegelf'",
        )),
    "plugins", list(nlist("gelf", nlist(
        "port", 12201,
        "ship_metadata", true,
        "host", 'remotehost.domain',
        "custom_fields", nlist("type", "remotegelf"),
        "level", list("%{level}"),
        "facility", "%{facility}",
        ))),
));


prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents/input";
"plugins" = append(nlist("gelf", nlist(
    # type is/can be set in output gelf filter. 
    # this will not forcefully overwrtie in 1.2.2
    "type", "remotegelf",
    "port", 12201,
)));


"plugins" = append(nlist("file", nlist(
    "path", list("/var/adm/ras/mmfs.log.latest"),
    "type", "gpfs",
    "tags", list("gpfs","storage"),
)));

prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents/filter";
"conditionals" = append(nlist(
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


"conditionals" = append(nlist(
    "type", "ifelseif",
    "expr", list(nlist(
        "left", "[type]",
        "test", "==",
        "right", "'gpfs'",
        )),
    "plugins", list(
        nlist("grok", nlist(
            "match", list(nlist(
                "name", "message", 
                "pattern", "%{GPFSLOG}"
                )),
            "patterns_dir", list("/usr/share/grok"),
            "add_field", nlist("program", "gpfs"),
            )),
        nlist("date", nlist(
            "match", nlist(
                "name", "timestamp", 
                "pattern", list("E MMM dd HH:mm:ss.SSS yyyy", "E MMM  d HH:mm:ss.SSS yyyy"),
                ),
            )),
        ),
));
