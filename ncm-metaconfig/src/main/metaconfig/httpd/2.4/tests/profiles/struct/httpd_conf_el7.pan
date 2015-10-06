structure template struct/httpd_conf_el7;

"directories" = list(
    nlist(
        "name", "/",
        "access", nlist("allowoverride", list("None")),
        "authz", list(nlist("all", "denied")),
        ),
    nlist(
        "name", "/var/www",
        "access", nlist("allowoverride", list("None")),
        "authz", list(nlist("all", "granted")),
        ),
    nlist(
        "name", "/var/www/html",
        "options", list("Indexes", "FollowSymLinks"),
        "access", nlist("allowoverride", list("None")),
        "authz", list(nlist("all", "granted")),
        ),
    nlist(
        "name", "/var/www/cgi-bin",
        "options", list("None"),
        "access", nlist("allowoverride", list("None")),
        "authz", list(nlist("all", "granted")),
        ),
);


"ifmodules" = list(
    nlist(
        "name", "mime_magic_module",
        "mimemagicfile", "conf/magic",
        ),
    nlist(
        "name", "mime_module",
        "type", nlist(
            "config", "/etc/mime.types",
            "add", list(
                nlist(
                    "name", "application/x-compress",
                    "target", list('.Z'),
                    ),
                nlist(
                    "name", "application/x-gzip",
                    "target", list('.gz', '.tgz'),
                    ),
                nlist(
                    "name", "text/html",
                    "target", list('.shtml'),
                    ),
                ),
            ),
        "outputfilter", nlist(
            "add", list(
                nlist(
                    "name", "INLCUDES",
                    "target", list(".shtml"),
                    ),
                ),
            ),
        ),
    nlist(
        "name", "log_config_module",
        "ifmodules" , list(nlist(
            "name", "logio_module",
            "log", nlist(
                "format", list(nlist(
                    "name", "combinedio",
                    "expr", '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O',
                    )),
                ),
            )),
        "log", nlist(
            "format", list(
                nlist(
                    "name", "combined",
                    "expr", '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
                    ),
                nlist(
                    "name", "common",
                    "expr", '%h %l %u %t \"%r\" %>s %b',
                    ),
                ),
            "custom", list(nlist(
                "name", "combined",
                "location", "logs/access_log",
                )),
            ),
        ),

    nlist(
        "name", "alias_module",
        "aliases", list(nlist(
            "url", "/cgi-bin/",
            "destination", "/var/www/cgi-bin/",
            "type", "script",
            )),
        ),
    nlist(
        "name", "dir_module",
        "directoryindex", list("index.html"),
        ),
);

"files" = list(
    nlist(
        "name", '^\.ht',
        "regex", true,
        "authz", list(nlist("all", "denied")),
        ),
);

"log/error" = "logs/error_log";
"log/level" = "warn";
