structure template struct/httpd_conf_el6;

"aliases" = list(
    nlist(
        "url", "/icons/",
        "destination", "/var/www/icons/",
        ),
    nlist(
        "url", "/cgi-bin/",
        "destination", "/var/www/cgi-bin/",
        "type", "script",
        ),
    nlist(
        "url", "/error/",
        "destination", "/var/www/error/",
        ),
);

"directories" = list(
    nlist(
        "name", "/",
        "options", list("FollowSymLinks"),
        "access", nlist(
            "allowoverride", list("None")),
        ),
    nlist(
        "name", "/var/www/html",
        "options", list("Indexes", "FollowSymLinks"),
        "access", nlist(
            "order", list("allow", "deny"),
            "allow", list("all"),
            "allowoverride", list("None")),
        ),
    nlist(
        "name", "/var/www/icons",
        "options", list("Indexes", "MultiViews", "FollowSymLinks"),
        "access", nlist(
            "order", list("allow", "deny"),
            "allow", list("all"),
            "allowoverride", list("None")),
        ),
    nlist(
        "name", "/var/www/cgi-bin",
        "options", list("None"),
        "access", nlist(
            "order", list("allow", "deny"),
            "allow", list("all"),
            "allowoverride", list("None")),
        ),
);
"files" = list(
    nlist(
        "name", '^\.ht',
        "regex", true,
        "access", nlist(
            "order", list("allow", "deny"),
            "deny", list("all"),
            "satisfy", "All"),
        ),
);

"browsermatch" = list(
    nlist(
        "match", 'Mozilla/2',
        "names", list("nokeepalive"),
        ),
    nlist(
        "match", 'MSIE 4\.0b2;',
        "names", list("nokeepalive", "downgrade-1.0", "force-response-1.0"),
        ),
    nlist(
        "match", 'RealPlayer 4\.0',
        "names", list("force-response-1.0"),
        ),
    nlist(
        "match", 'Java/1\.0',
        "names", list("force-response-1.0"),
        ),
    nlist(
        "match", 'JDK/1\.0',
        "names", list("force-response-1.0"),
        ),
    nlist(
        "match", 'Microsoft Data Access Internet Publishing Provider',
        "names", list("redirect-carefully"),
        ),
    nlist(
        "match", 'MS FrontPage',
        "names", list("redirect-carefully"),
        ),
    nlist(
        "match", '^WebDrive',
        "names", list("redirect-carefully"),
        ),
    nlist(
        "match", '^WebDAVFS/1.[0123]',
        "names", list("redirect-carefully"),
        ),
    nlist(
        "match", '^gnome-vfs/1.0',
        "names", list("redirect-carefully"),
        ),
    nlist(
        "match", '^XML Spy',
        "names", list("redirect-carefully"),
        ),
    nlist(
        "match", '^Dreamweaver-WebDAV-SCM1',
        "names", list("redirect-carefully"),
        ),
);

"modules" = {
    append(nlist(
        "name", "auth_basic_module",
        "path", "modules/mod_auth_basic.so"));
    append(nlist(
        "name", "auth_digest_module",
        "path", "modules/mod_auth_digest.so"));
    append(nlist(
        "name", "authn_file_module",
        "path", "modules/mod_authn_file.so"));
    append(nlist(
        "name", "authn_alias_module",
        "path", "modules/mod_authn_alias.so"));
    append(nlist(
        "name", "authn_anon_module",
        "path", "modules/mod_authn_anon.so"));
    append(nlist(
        "name", "authn_dbm_module",
        "path", "modules/mod_authn_dbm.so"));
    append(nlist(
        "name", "authn_default_module",
        "path", "modules/mod_authn_default.so"));
    append(nlist(
        "name", "authz_host_module",
        "path", "modules/mod_authz_host.so"));
    append(nlist(
        "name", "authz_user_module",
        "path", "modules/mod_authz_user.so"));
    append(nlist(
        "name", "authz_owner_module",
        "path", "modules/mod_authz_owner.so"));
    append(nlist(
        "name", "authz_groupfile_module",
        "path", "modules/mod_authz_groupfile.so"));
    append(nlist(
        "name", "authz_dbm_module",
        "path", "modules/mod_authz_dbm.so"));
    append(nlist(
        "name", "authz_default_module",
        "path", "modules/mod_authz_default.so"));
    append(nlist(
        "name", "ldap_module",
        "path", "modules/mod_ldap.so"));
    append(nlist(
        "name", "authnz_ldap_module",
        "path", "modules/mod_authnz_ldap.so"));
    append(nlist(
        "name", "include_module",
        "path", "modules/mod_include.so"));
    append(nlist(
        "name", "log_config_module",
        "path", "modules/mod_log_config.so"));
    append(nlist(
        "name", "logio_module",
        "path", "modules/mod_logio.so"));
    append(nlist(
        "name", "env_module",
        "path", "modules/mod_env.so"));
    append(nlist(
        "name", "ext_filter_module",
        "path", "modules/mod_ext_filter.so"));
    append(nlist(
        "name", "mime_magic_module",
        "path", "modules/mod_mime_magic.so"));
    append(nlist(
        "name", "expires_module",
        "path", "modules/mod_expires.so"));
    append(nlist(
        "name", "deflate_module",
        "path", "modules/mod_deflate.so"));
    append(nlist(
        "name", "headers_module",
        "path", "modules/mod_headers.so"));
    append(nlist(
        "name", "usertrack_module",
        "path", "modules/mod_usertrack.so"));
    append(nlist(
        "name", "setenvif_module",
        "path", "modules/mod_setenvif.so"));
    append(nlist(
        "name", "mime_module",
        "path", "modules/mod_mime.so"));
    append(nlist(
        "name", "dav_module",
        "path", "modules/mod_dav.so"));
    append(nlist(
        "name", "status_module",
        "path", "modules/mod_status.so"));
    append(nlist(
        "name", "autoindex_module",
        "path", "modules/mod_autoindex.so"));
    append(nlist(
        "name", "info_module",
        "path", "modules/mod_info.so"));
    append(nlist(
        "name", "dav_fs_module",
        "path", "modules/mod_dav_fs.so"));
    append(nlist(
        "name", "vhost_alias_module",
        "path", "modules/mod_vhost_alias.so"));
    append(nlist(
        "name", "negotiation_module",
        "path", "modules/mod_negotiation.so"));
    append(nlist(
        "name", "dir_module",
        "path", "modules/mod_dir.so"));
    append(nlist(
        "name", "actions_module",
        "path", "modules/mod_actions.so"));
    append(nlist(
        "name", "speling_module",
        "path", "modules/mod_speling.so"));
    append(nlist(
        "name", "userdir_module",
        "path", "modules/mod_userdir.so"));
    append(nlist(
        "name", "alias_module",
        "path", "modules/mod_alias.so"));
    append(nlist(
        "name", "substitute_module",
        "path", "modules/mod_substitute.so"));
    append(nlist(
        "name", "rewrite_module",
        "path", "modules/mod_rewrite.so"));
    append(nlist(
        "name", "proxy_module",
        "path", "modules/mod_proxy.so"));
    append(nlist(
        "name", "proxy_balancer_module",
        "path", "modules/mod_proxy_balancer.so"));
    append(nlist(
        "name", "proxy_ftp_module",
        "path", "modules/mod_proxy_ftp.so"));
    append(nlist(
        "name", "proxy_http_module",
        "path", "modules/mod_proxy_http.so"));
    append(nlist(
        "name", "proxy_ajp_module",
        "path", "modules/mod_proxy_ajp.so"));
    append(nlist(
        "name", "proxy_connect_module",
        "path", "modules/mod_proxy_connect.so"));
    append(nlist(
        "name", "cache_module",
        "path", "modules/mod_cache.so"));
    append(nlist(
        "name", "suexec_module",
        "path", "modules/mod_suexec.so"));
    append(nlist(
        "name", "disk_cache_module",
        "path", "modules/mod_disk_cache.so"));
    append(nlist(
        "name", "cgi_module",
        "path", "modules/mod_cgi.so"));
    append(nlist(
        "name", "version_module",
        "path", "modules/mod_version.so"));
};

"ifmodules" = list(
    nlist(
        "name", "prefork.c",
        "startservers", 8,
        "minspareservers", 5,
        "maxspareservers", 20,
        "serverlimit", 256,
        "maxclients", 256,
        "maxrequestsperchild", 4000,
        ),
    nlist(
        "name", "worker.c",
        "startservers", 4,
        "maxclients", 300,
        "minsparethreads", 25,
        "maxsparethreads", 75,
        "threadsperchild", 25,
        "maxrequestsperchild", 0,
        ),
    nlist(
        "name", "mod_userdir.c",
        "userdir", "disabled",
        ),
    nlist(
        "name", "mod_mime_magic.c",
        "mimemagicfile", "conf/magic",
        ),
    nlist(
        "name", "mod_dav_fs.c",
        "davlockdb", "/var/lib/dav/lockdb",
        ),
    nlist(
        "name", "mod_negotiation.c",
        "ifmodules" , list(nlist(
            "name", "mod_include.c",
            "directories", list(nlist(
                "name", "/var/www/error",
                "options", list("IncludesNoExec"),
                "access", nlist(
                    "order", list("allow", "deny"),
                    "allow", list("all"),
                    "allowoverride", list("None")
                    ),
                "lang", nlist(
                    "priority", list("en", "es", "de", "fr"),
                    "forcepriority", list("Prefer", "Fallback"),
                    ),
                "handler", nlist(
                    "add", list(nlist(
                        "name", "type-map",
                        "target", list("var"),
                        )),
                    ),
                "outputfilter", nlist(
                    "add", list(nlist(
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
    nlist(
        "name", "combined",
        "expr", '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"',
        ),
    nlist(
        "name", "common",
        "expr", '%h %l %u %t \"%r\" %>s %b',
        ),
    nlist(
        "name", "referer",
        "expr", '%{Referer}i -> %U',
        ), 
    nlist(
        "name", "agent",
        "expr", '%{User-agent}i', 
        ),
    nlist(
        "name", "ssl_combined",
        "expr", '%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b',
        ),
 );
"log/custom" = list(
    nlist(
        "name", "combined",
        "location", "logs/access_log",
        ),
);

"global/directoryindex" = list("index.html","index.html.var");


"type/config" = "/etc/mime.types";
"type/default" = "text/plain";
"type/add" = list(
    nlist(
        "name", "application/x-compress",
        "target", list(".Z"),
        ),
    nlist(
        "name", "application/x-gzip",
        "target", list(".gz", ".tgz"),
        ),
    nlist(
        "name", "application/x-x509-ca-cert",
        "target", list(".crt"),
        ),
    nlist(
        "name", "application/x-pkcs7-crl",
        "target", list(".crl"),
        ),
    nlist(
        "name", "text/html",
        "target", list(".shtml"),
        ),
);

"handler/add" = list(
    nlist(
        "name", "type-map",
        "target", list("var"),
        ),
);

"outputfilter/add" = list(
    nlist(
        "name", "INCLUDES",
        "target", list(".shtml"),
        ),
);

"icon/default" = "/icons/unknown.gif";
"icon/addbyencoding" = list(
    nlist(
        "icon", "(CMP,/icons/compressed.gif)",
        "names", list("x-compress x-gzip")
        ),
);
"icon/addbytype" = list(
    nlist(
        "icon", "(TXT,/icons/text.gif)",
        "names", list("text/*"),
        ),
    nlist(
        "icon", "(IMG,/icons/image2.gif)",
        "names", list("image/*"),
        ),
    nlist(
        "icon", "(SND,/icons/sound2.gif)",
        "names", list("audio/*"),
        ),
    nlist(
        "icon", "(VID,/icons/movie.gif)",
        "names", list("video/*"),
        ),
);
"icon/add" = list(
    nlist(
        "icon", "/icons/binary.gif",
        "names", list(".bin", ".exe"),
        ),
    nlist(
        "icon", "/icons/binhex.gif",
        "names", list(".hqx"),
        ),
    nlist(
        "icon", "/icons/tar.gif",
        "names", list(".tar"),
        ),
    nlist(
        "icon", "/icons/world2.gif",
        "names", list(".wrl", ".wrl.gz", ".vrml", ".vrm", ".iv"),
        ),
    nlist(
        "icon", "/icons/compressed.gif",
        "names", list(".Z", ".z", ".tgz", ".gz", ".zip"),
        ),
    nlist(
        "icon", "/icons/a.gif",
        "names", list(".ps", ".ai", ".eps"),
        ),
    nlist(
        "icon", "/icons/layout.gif",
        "names", list(".html", ".shtml", ".htm", ".pdf"),
        ),
    nlist(
        "icon", "/icons/text.gif",
        "names", list(".txt"),
        ),
    nlist(
        "icon", "/icons/c.gif",
        "names", list(".c"),
        ),
    nlist(
        "icon", "/icons/p.gif",
        "names", list(".pl", ".py"),
        ),
    nlist(
        "icon", "/icons/f.gif",
        "names", list(".for"),
        ),
    nlist(
        "icon", "/icons/dvi.gif",
        "names", list(".dvi"),
        ),
    nlist(
        "icon", "/icons/uuencoded.gif",
        "names", list(".uu"),
        ),
    nlist(
        "icon", "/icons/script.gif",
        "names", list(".conf", ".sh", ".shar", ".csh", ".ksh", ".tcl"),
        ),
    nlist(
        "icon", "/icons/tex.gif",
        "names", list(".tex"),
        ),
    nlist(
        "icon", "/icons/bomb.gif",
        "names", list("core"),
        ),
    nlist(
        "icon", "/icons/back.gif",
        "names", list(".."),
        ),
    nlist(
        "icon", "/icons/hand.right.gif",
        "names", list("README"),
        ),
    nlist(
        "icon", "/icons/folder.gif",
        "names", list("^^DIRECTORY^^"),
        ),
    nlist(
        "icon", "/icons/blank.gif",
        "names", list("^^BLANKICON^^"),
        ),
);


"lang/priority" = list("en", "ca", "cs", "da", "de", "el", "eo", "es", "et", "fr", "he", "hr", "it", 
                  "ja", "ko", "ltz", "nl", "nn", "no", "pl", "pt", "pt-BR", "ru", "sv", "zh-CN", "zh-TW");
"lang/forcepriority" = list("Prefer", "Fallback");
"lang/add" = list(
    nlist(
        "lang", "ca",
        "names", list(".ca"),
        ),
    nlist(
        "lang", "cs",
        "names", list(".cz", ".cs"),
        ),
    nlist(
        "lang", "da",
        "names", list(".dk"),
        ),
    nlist(
        "lang", "de",
        "names", list(".de"),
        ),
    nlist(
        "lang", "el",
        "names", list(".el"),
        ),
    nlist(
        "lang", "en",
        "names", list(".en"),
        ),
    nlist(
        "lang", "eo",
        "names", list(".eo"),
        ),
    nlist(
        "lang", "es",
        "names", list(".es"),
        ),
    nlist(
        "lang", "et",
        "names", list(".et"),
        ),
    nlist(
        "lang", "fr",
        "names", list(".fr"),
        ),
    nlist(
        "lang", "he",
        "names", list(".he"),
        ),
    nlist(
        "lang", "hr",
        "names", list(".hr"),
        ),
    nlist(
        "lang", "it",
        "names", list(".it"),
        ),
    nlist(
        "lang", "ja",
        "names", list(".ja"),
        ),
    nlist(
        "lang", "ko",
        "names", list(".ko"),
        ),
    nlist(
        "lang", "ltz",
        "names", list(".ltz"),
        ),
    nlist(
        "lang", "nl",
        "names", list(".nl"),
        ),
    nlist(
        "lang", "nn",
        "names", list(".nn"),
        ),
    nlist(
        "lang", "no",
        "names", list(".no"),
        ),
    nlist(
        "lang", "pl",
        "names", list(".po"),
        ),
    nlist(
        "lang", "pt",
        "names", list(".pt"),
        ),
    nlist(
        "lang", "pt-BR",
        "names", list(".pt-br"),
        ),
    nlist(
        "lang", "ru",
        "names", list(".ru"),
        ),
    nlist(
        "lang", "sv",
        "names", list(".sv"),
        ),
    nlist(
        "lang", "zh-CN",
        "names", list(".zh-cn"),
        ),
    nlist(
        "lang", "zh-TW",
        "names", list(".zh-tw"),
        ),
);

