structure template struct/httpd_conf_el7;

"directories" = list(
    dict(
        "name", "/",
        "access", dict("allowoverride", list("None")),
        "authz", list(dict("all", "denied")),
        ),
    dict(
        "name", "/var/www",
        "access", dict("allowoverride", list("None")),
        "authz", list(dict("all", "granted")),
        ),
    dict(
        "name", "/var/www/html",
        "options", list("Indexes", "FollowSymLinks"),
        "access", dict("allowoverride", list("None")),
        "authz", list(dict("all", "granted")),
        ),
    dict(
        "name", "/var/www/cgi-bin",
        "options", list("None"),
        "access", dict("allowoverride", list("None")),
        "authz", list(dict("all", "granted")),
        ),
);


"ifmodules" = list(
    dict(
        "name", "mime_magic_module",
        "mimemagicfile", "conf/magic",
        ),
    dict(
        "name", "mime_module",
        "type", dict(
            "config", "/etc/mime.types",
            "add", list(
                dict(
                    "name", "application/x-compress",
                    "target", list('.Z'),
                    ),
                dict(
                    "name", "application/x-gzip",
                    "target", list('.gz', '.tgz'),
                    ),
                dict(
                    "name", "text/html",
                    "target", list('.shtml'),
                    ),
                ),
            ),
        "outputfilter", dict(
            "add", list(
                dict(
                    "name", "INLCUDES",
                    "target", list(".shtml"),
                    ),
                ),
            ),
        ),
    dict(
        "name", "log_config_module",
        "ifmodules" , list(dict(
            "name", "logio_module",
            "log", dict(
                "format", list(dict(
                    "name", "combinedio",
                    "expr", '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O',
                    )),
                ),
            )),
        "log", dict(
            "format", list(
                dict(
                    "name", "combined",
                    "expr", '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
                    ),
                dict(
                    "name", "common",
                    "expr", '%h %l %u %t \"%r\" %>s %b',
                    ),
                ),
            "custom", list(dict(
                "name", "combined",
                "location", "logs/access_log",
                )),
            ),
        ),

    dict(
        "name", "alias_module",
        "aliases", list(dict(
            "url", "/cgi-bin/",
            "destination", "/var/www/cgi-bin/",
            "type", "script",
            )),
        ),
    dict(
        "name", "dir_module",
        "directoryindex", list("index.html"),
        ),
);

"files" = list(
    dict(
        "name", '^\.ht',
        "regex", true,
        "authz", list(dict("all", "denied")),
        ),
);

"log/error" = "logs/error_log";
"log/level" = "warn";

"includes" = list("conf.modules.d/*.conf");
"includesoptional" = list("conf.d/*.conf");
