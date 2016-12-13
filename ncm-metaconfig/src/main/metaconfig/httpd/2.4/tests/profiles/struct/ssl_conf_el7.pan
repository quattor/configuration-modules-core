structure template struct/ssl_conf_el7;

"listen" = list(
    dict("port", 443, "protocol", "https"),
);
"ssl" = dict(
    "passphrasedialog", "exec:/usr/libexec/httpd-ssl-pass-dialog",

    "sessioncache", "shmcb:/run/httpd/sslcache(512000)",
    "sessioncachetimeout", 300,

    "mutex", "default",

    "randomseed", list(
        list("startup", "file:/dev/urandom", "256"),
        list("connect", "builtin"),
    ),
    "cryptodevice", list("builtin"),
);

"vhosts/base" = create("struct/default_vhost",
    "documentroot", "/var/www/cgi-bin",
    "port", 443);


"vhosts/base/log/error" = "logs/ssl_error_log";
"vhosts/base/log/transfer" = "logs/ssl_access_log";
"vhosts/base/log/level" = "warn";
"vhosts/base/log/custom" = list(
    dict(
        "location", "logs/ssl_request_log",
        "name", '"%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"',
    ),
);


"vhosts/base/ssl/engine" = true;
# list("all", "-SSLv2") not allowed
"vhosts/base/ssl/protocol" =  list("TLSv1");
# list("ALL", "!ADH", "!EXPORT", "!SSLv2", "RC4", "RSA", "+HIGH", "+MEDIUM", "+LOW")
"vhosts/base/ssl/ciphersuite" = list("TLSv1");
"vhosts/base/ssl/certificatefile" = "/etc/pki/tls/certs/localhost.crt";
"vhosts/base/ssl/certificatekeyfile" = "/etc/pki/tls/private/localhost.key";

"vhosts/base/files" = list(dict(
    "regex", true,
    "name", '\.(cgi|shtml|phtml|php3?)$',
    "ssl", dict(
        "options", list("+StdEnvVars"),
    ),
));
"vhosts/base/directories" = list(dict(
    "name", "/var/www/cgi-bin",
    "ssl", dict(
        "options", list("+StdEnvVars"),
    ),
));
"vhosts/base/browsermatch" = list(dict(
    "match", ".*MSIE.*",
    "names", list("nokeepalive", "ssl-unclean-shutdown", "downgrade-1.0", "force-response-1.0"),
));
