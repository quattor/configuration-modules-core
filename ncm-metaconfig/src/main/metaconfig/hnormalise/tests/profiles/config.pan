object template config;

include 'metaconfig/hnormalise/config';

prefix "/software/components/metaconfig/services/{/etc/hnormalise.yaml}/contents";

"logging" = dict(
    "frequency", 100000,
);

"input" = dict(
    "zeromq", dict(
        "method", "pull",
        "host", "lo",
        "port", 31338,
    ),
);

"output" = dict(
    "zeromq", dict(
        "success", dict(
            "method", "push",
            "host", "localhost",
            "port", 27001,
        ),
        "failure", dict(
            "method", "push",
            "host", "localhost",
            "port", 27002,
        ),
    ),
);

"fields" = list(
    list("@source_host", "hostname"),
    list("message", "msg"),
    list("syslog_version", "version"),
    list("syslog_abspri", "pri"),
    list("program", "app_name"),
);
