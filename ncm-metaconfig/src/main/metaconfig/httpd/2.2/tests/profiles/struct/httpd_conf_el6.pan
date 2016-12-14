structure template struct/httpd_conf_el6;

"aliases" = list(
    dict(
        "url", "/icons/",
        "destination", "/var/www/icons/",
        ),
    dict(
        "url", "/cgi-bin/",
        "destination", "/var/www/cgi-bin/",
        "type", "script",
        ),
    dict(
        "url", "/error/",
        "destination", "/var/www/error/",
        ),
);

"directories" = list(
    dict(
        "name", "/",
        "options", list("FollowSymLinks"),
        "access", dict(
            "allowoverride", list("None")),
        ),
    dict(
        "name", "/var/www/html",
        "options", list("Indexes", "FollowSymLinks"),
        "access", dict(
            "order", list("allow", "deny"),
            "allow", list("all"),
            "allowoverride", list("None")),
        ),
    dict(
        "name", "/var/www/icons",
        "options", list("Indexes", "MultiViews", "FollowSymLinks"),
        "access", dict(
            "order", list("allow", "deny"),
            "allow", list("all"),
            "allowoverride", list("None")),
        ),
    dict(
        "name", "/var/www/cgi-bin",
        "options", list("None"),
        "access", dict(
            "order", list("allow", "deny"),
            "allow", list("all"),
            "allowoverride", list("None")),
        ),
);
"files" = list(
    dict(
        "name", '^\.ht',
        "regex", true,
        "access", dict(
            "order", list("allow", "deny"),
            "deny", list("all"),
            "satisfy", "All"),
        ),
);

"browsermatch" = list(
    dict(
        "match", 'Mozilla/2',
        "names", list("nokeepalive"),
        ),
    dict(
        "match", 'MSIE 4\.0b2;',
        "names", list("nokeepalive", "downgrade-1.0", "force-response-1.0"),
        ),
    dict(
        "match", 'RealPlayer 4\.0',
        "names", list("force-response-1.0"),
        ),
    dict(
        "match", 'Java/1\.0',
        "names", list("force-response-1.0"),
        ),
    dict(
        "match", 'JDK/1\.0',
        "names", list("force-response-1.0"),
        ),
    dict(
        "match", 'Microsoft Data Access Internet Publishing Provider',
        "names", list("redirect-carefully"),
        ),
    dict(
        "match", 'MS FrontPage',
        "names", list("redirect-carefully"),
        ),
    dict(
        "match", '^WebDrive',
        "names", list("redirect-carefully"),
        ),
    dict(
        "match", '^WebDAVFS/1.[0123]',
        "names", list("redirect-carefully"),
        ),
    dict(
        "match", '^gnome-vfs/1.0',
        "names", list("redirect-carefully"),
        ),
    dict(
        "match", '^XML Spy',
        "names", list("redirect-carefully"),
        ),
    dict(
        "match", '^Dreamweaver-WebDAV-SCM1',
        "names", list("redirect-carefully"),
        ),
);

"modules" = {
    append(dict(
        "name", "auth_basic_module",
        "path", "modules/mod_auth_basic.so"));
    append(dict(
        "name", "auth_digest_module",
        "path", "modules/mod_auth_digest.so"));
    append(dict(
        "name", "authn_file_module",
        "path", "modules/mod_authn_file.so"));
    append(dict(
        "name", "authn_alias_module",
        "path", "modules/mod_authn_alias.so"));
    append(dict(
        "name", "authn_anon_module",
        "path", "modules/mod_authn_anon.so"));
    append(dict(
        "name", "authn_dbm_module",
        "path", "modules/mod_authn_dbm.so"));
    append(dict(
        "name", "authn_default_module",
        "path", "modules/mod_authn_default.so"));
    append(dict(
        "name", "authz_host_module",
        "path", "modules/mod_authz_host.so"));
    append(dict(
        "name", "authz_user_module",
        "path", "modules/mod_authz_user.so"));
    append(dict(
        "name", "authz_owner_module",
        "path", "modules/mod_authz_owner.so"));
    append(dict(
        "name", "authz_groupfile_module",
        "path", "modules/mod_authz_groupfile.so"));
    append(dict(
        "name", "authz_dbm_module",
        "path", "modules/mod_authz_dbm.so"));
    append(dict(
        "name", "authz_default_module",
        "path", "modules/mod_authz_default.so"));
    append(dict(
        "name", "ldap_module",
        "path", "modules/mod_ldap.so"));
    append(dict(
        "name", "authnz_ldap_module",
        "path", "modules/mod_authnz_ldap.so"));
    append(dict(
        "name", "include_module",
        "path", "modules/mod_include.so"));
    append(dict(
        "name", "log_config_module",
        "path", "modules/mod_log_config.so"));
    append(dict(
        "name", "logio_module",
        "path", "modules/mod_logio.so"));
    append(dict(
        "name", "env_module",
        "path", "modules/mod_env.so"));
    append(dict(
        "name", "ext_filter_module",
        "path", "modules/mod_ext_filter.so"));
    append(dict(
        "name", "mime_magic_module",
        "path", "modules/mod_mime_magic.so"));
    append(dict(
        "name", "expires_module",
        "path", "modules/mod_expires.so"));
    append(dict(
        "name", "deflate_module",
        "path", "modules/mod_deflate.so"));
    append(dict(
        "name", "headers_module",
        "path", "modules/mod_headers.so"));
    append(dict(
        "name", "usertrack_module",
        "path", "modules/mod_usertrack.so"));
    append(dict(
        "name", "setenvif_module",
        "path", "modules/mod_setenvif.so"));
    append(dict(
        "name", "mime_module",
        "path", "modules/mod_mime.so"));
    append(dict(
        "name", "dav_module",
        "path", "modules/mod_dav.so"));
    append(dict(
        "name", "status_module",
        "path", "modules/mod_status.so"));
    append(dict(
        "name", "autoindex_module",
        "path", "modules/mod_autoindex.so"));
    append(dict(
        "name", "info_module",
        "path", "modules/mod_info.so"));
    append(dict(
        "name", "dav_fs_module",
        "path", "modules/mod_dav_fs.so"));
    append(dict(
        "name", "vhost_alias_module",
        "path", "modules/mod_vhost_alias.so"));
    append(dict(
        "name", "negotiation_module",
        "path", "modules/mod_negotiation.so"));
    append(dict(
        "name", "dir_module",
        "path", "modules/mod_dir.so"));
    append(dict(
        "name", "actions_module",
        "path", "modules/mod_actions.so"));
    append(dict(
        "name", "speling_module",
        "path", "modules/mod_speling.so"));
    append(dict(
        "name", "userdir_module",
        "path", "modules/mod_userdir.so"));
    append(dict(
        "name", "alias_module",
        "path", "modules/mod_alias.so"));
    append(dict(
        "name", "substitute_module",
        "path", "modules/mod_substitute.so"));
    append(dict(
        "name", "rewrite_module",
        "path", "modules/mod_rewrite.so"));
    append(dict(
        "name", "proxy_module",
        "path", "modules/mod_proxy.so"));
    append(dict(
        "name", "proxy_balancer_module",
        "path", "modules/mod_proxy_balancer.so"));
    append(dict(
        "name", "proxy_ftp_module",
        "path", "modules/mod_proxy_ftp.so"));
    append(dict(
        "name", "proxy_http_module",
        "path", "modules/mod_proxy_http.so"));
    append(dict(
        "name", "proxy_ajp_module",
        "path", "modules/mod_proxy_ajp.so"));
    append(dict(
        "name", "proxy_connect_module",
        "path", "modules/mod_proxy_connect.so"));
    append(dict(
        "name", "cache_module",
        "path", "modules/mod_cache.so"));
    append(dict(
        "name", "suexec_module",
        "path", "modules/mod_suexec.so"));
    append(dict(
        "name", "disk_cache_module",
        "path", "modules/mod_disk_cache.so"));
    append(dict(
        "name", "cgi_module",
        "path", "modules/mod_cgi.so"));
    append(dict(
        "name", "version_module",
        "path", "modules/mod_version.so"));
};

"ifmodules" = list(
    dict(
        "name", "prefork.c",
        "startservers", 8,
        "minspareservers", 5,
        "maxspareservers", 20,
        "serverlimit", 256,
        "maxclients", 256,
        "maxrequestsperchild", 4000,
        ),
    dict(
        "name", "worker.c",
        "startservers", 4,
        "maxclients", 300,
        "minsparethreads", 25,
        "maxsparethreads", 75,
        "threadsperchild", 25,
        "maxrequestsperchild", 0,
        ),
    dict(
        "name", "mod_userdir.c",
        "userdir", "disabled",
        ),
    dict(
        "name", "mod_mime_magic.c",
        "mimemagicfile", "conf/magic",
        ),
    dict(
        "name", "mod_dav_fs.c",
        "davlockdb", "/var/lib/dav/lockdb",
        ),
    dict(
        "name", "mod_negotiation.c",
        "ifmodules" , list(dict(
            "name", "mod_include.c",
            "directories", list(dict(
                "name", "/var/www/error",
                "options", list("IncludesNoExec"),
                "access", dict(
                    "order", list("allow", "deny"),
                    "allow", list("all"),
                    "allowoverride", list("None")
                    ),
                "lang", dict(
                    "priority", list("en", "es", "de", "fr"),
                    "forcepriority", list("Prefer", "Fallback"),
                    ),
                "handler", dict(
                    "add", list(dict(
                        "name", "type-map",
                        "target", list("var"),
                        )),
                    ),
                "outputfilter", dict(
                    "add", list(dict(
                        "name", "Includes",
                        "target", list("html")
                        )),
                    ),
                )),
            )),
        ),
);


"log/error" = "logs/error_log";
"log/level" = "warn";
"log/format" = list(
    dict(
        "name", "combined",
        "expr", '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
        ),
    dict(
        "name", "common",
        "expr", '%h %l %u %t \"%r\" %>s %b',
        ),
    dict(
        "name", "referer",
        "expr", '%{Referer}i -> %U',
        ),
    dict(
        "name", "agent",
        "expr", '%{User-agent}i',
        ),
    dict(
        "name", "ssl_combined",
        "expr", '%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b',
        ),
);
"log/custom" = list(
    dict(
        "name", "combined",
        "location", "logs/access_log",
        ),
);

"global/directoryindex" = list("index.html", "index.html.var");


"type/config" = "/etc/mime.types";
"type/default" = "text/plain";
"type/add" = list(
    dict(
        "name", "application/x-compress",
        "target", list(".Z"),
        ),
    dict(
        "name", "application/x-gzip",
        "target", list(".gz", ".tgz"),
        ),
    dict(
        "name", "application/x-x509-ca-cert",
        "target", list(".crt"),
        ),
    dict(
        "name", "application/x-pkcs7-crl",
        "target", list(".crl"),
        ),
    dict(
        "name", "text/html",
        "target", list(".shtml"),
        ),
);

"handler/add" = list(
    dict(
        "name", "type-map",
        "target", list("var"),
        ),
);

"outputfilter/add" = list(
    dict(
        "name", "INCLUDES",
        "target", list(".shtml"),
        ),
);

"icon/default" = "/icons/unknown.gif";
"icon/addbyencoding" = list(
    dict(
        "icon", "(CMP,/icons/compressed.gif)",
        "names", list("x-compress x-gzip")
        ),
);
"icon/addbytype" = list(
    dict(
        "icon", "(TXT,/icons/text.gif)",
        "names", list("text/*"),
        ),
    dict(
        "icon", "(IMG,/icons/image2.gif)",
        "names", list("image/*"),
        ),
    dict(
        "icon", "(SND,/icons/sound2.gif)",
        "names", list("audio/*"),
        ),
    dict(
        "icon", "(VID,/icons/movie.gif)",
        "names", list("video/*"),
        ),
);
"icon/add" = list(
    dict(
        "icon", "/icons/binary.gif",
        "names", list(".bin", ".exe"),
        ),
    dict(
        "icon", "/icons/binhex.gif",
        "names", list(".hqx"),
        ),
    dict(
        "icon", "/icons/tar.gif",
        "names", list(".tar"),
        ),
    dict(
        "icon", "/icons/world2.gif",
        "names", list(".wrl", ".wrl.gz", ".vrml", ".vrm", ".iv"),
        ),
    dict(
        "icon", "/icons/compressed.gif",
        "names", list(".Z", ".z", ".tgz", ".gz", ".zip"),
        ),
    dict(
        "icon", "/icons/a.gif",
        "names", list(".ps", ".ai", ".eps"),
        ),
    dict(
        "icon", "/icons/layout.gif",
        "names", list(".html", ".shtml", ".htm", ".pdf"),
        ),
    dict(
        "icon", "/icons/text.gif",
        "names", list(".txt"),
        ),
    dict(
        "icon", "/icons/c.gif",
        "names", list(".c"),
        ),
    dict(
        "icon", "/icons/p.gif",
        "names", list(".pl", ".py"),
        ),
    dict(
        "icon", "/icons/f.gif",
        "names", list(".for"),
        ),
    dict(
        "icon", "/icons/dvi.gif",
        "names", list(".dvi"),
        ),
    dict(
        "icon", "/icons/uuencoded.gif",
        "names", list(".uu"),
        ),
    dict(
        "icon", "/icons/script.gif",
        "names", list(".conf", ".sh", ".shar", ".csh", ".ksh", ".tcl"),
        ),
    dict(
        "icon", "/icons/tex.gif",
        "names", list(".tex"),
        ),
    dict(
        "icon", "/icons/bomb.gif",
        "names", list("core"),
        ),
    dict(
        "icon", "/icons/back.gif",
        "names", list(".."),
        ),
    dict(
        "icon", "/icons/hand.right.gif",
        "names", list("README"),
        ),
    dict(
        "icon", "/icons/folder.gif",
        "names", list("^^DIRECTORY^^"),
        ),
    dict(
        "icon", "/icons/blank.gif",
        "names", list("^^BLANKICON^^"),
        ),
);


"lang/priority" = list(
    "en", "ca", "cs", "da", "de", "el", "eo", "es", "et", "fr", "he", "hr", "it",
    "ja", "ko", "ltz", "nl", "nn", "no", "pl", "pt", "pt-BR", "ru", "sv", "zh-CN", "zh-TW",
);
"lang/forcepriority" = list("Prefer", "Fallback");
"lang/add" = list(
    dict(
        "lang", "ca",
        "names", list(".ca"),
        ),
    dict(
        "lang", "cs",
        "names", list(".cz", ".cs"),
        ),
    dict(
        "lang", "da",
        "names", list(".dk"),
        ),
    dict(
        "lang", "de",
        "names", list(".de"),
        ),
    dict(
        "lang", "el",
        "names", list(".el"),
        ),
    dict(
        "lang", "en",
        "names", list(".en"),
        ),
    dict(
        "lang", "eo",
        "names", list(".eo"),
        ),
    dict(
        "lang", "es",
        "names", list(".es"),
        ),
    dict(
        "lang", "et",
        "names", list(".et"),
        ),
    dict(
        "lang", "fr",
        "names", list(".fr"),
        ),
    dict(
        "lang", "he",
        "names", list(".he"),
        ),
    dict(
        "lang", "hr",
        "names", list(".hr"),
        ),
    dict(
        "lang", "it",
        "names", list(".it"),
        ),
    dict(
        "lang", "ja",
        "names", list(".ja"),
        ),
    dict(
        "lang", "ko",
        "names", list(".ko"),
        ),
    dict(
        "lang", "ltz",
        "names", list(".ltz"),
        ),
    dict(
        "lang", "nl",
        "names", list(".nl"),
        ),
    dict(
        "lang", "nn",
        "names", list(".nn"),
        ),
    dict(
        "lang", "no",
        "names", list(".no"),
        ),
    dict(
        "lang", "pl",
        "names", list(".po"),
        ),
    dict(
        "lang", "pt",
        "names", list(".pt"),
        ),
    dict(
        "lang", "pt-BR",
        "names", list(".pt-br"),
        ),
    dict(
        "lang", "ru",
        "names", list(".ru"),
        ),
    dict(
        "lang", "sv",
        "names", list(".sv"),
        ),
    dict(
        "lang", "zh-CN",
        "names", list(".zh-cn"),
        ),
    dict(
        "lang", "zh-TW",
        "names", list(".zh-tw"),
        ),
);
