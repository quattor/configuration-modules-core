object template graphite-web;

include 'metaconfig/httpd/schema';

bind "/software/components/metaconfig/services/{/etc/httpd/conf.d/graphite-web.conf}/contents" = httpd_vhosts;

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/graphite-web.conf}";
"module" = "httpd/generic_server";
"daemons/httpd" = "restart";

variable HTTPD_OS_FLAVOUR ?= 'el6';
variable FULL_HOSTNAME = 'myhost.domain';
variable HOSTNAME = 'myhost';
variable DB_IP = dict(HOSTNAME, '1.2.3.4');

"/software/components/metaconfig/services/{/etc/httpd/conf.d/graphite-web.conf}/contents/vhosts/graphiteweb" = {
    base=create(format('struct/ssl_conf_%s', HTTPD_OS_FLAVOUR));

    pubvhost=create('struct/public_vhost');

    foreach(idx;val;list('certificatefile', 'certificatekeyfile', 'cacertificatefile')) {
        base['vhosts']['base']['ssl'][val] = pubvhost['ssl'][val];
    };

    base['vhosts']['base'];
};

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/graphite-web.conf}/contents";
"listen" = append(dict("port", 444));

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/graphite-web.conf}/contents/vhosts/graphiteweb";
"ip/0" = DB_IP[HOSTNAME];
"port" = 444;
"servername" = FULL_HOSTNAME;

"documentroot" = "/usr/share/graphite/webapp";
"log/level" = "info";
"log/error" = "logs/graphite-web_error_log";
"log/transfer" = null;
"log/custom" = list(dict(
    "location", "logs/graphite-web_access_log",
    "name", "combined"
));

"aliases" = {
    append(dict(
        "url", "/media/",
        "destination", "/usr/lib/python2.6/site-packages/django/contrib/admin/media/",
        ));
    append(dict(
        "url", "/",
        "destination", "/usr/share/graphite/graphite-web.wsgi",
        "type", "wsgiscript",
        ));
};


"locations" = {
    append(dict(
        "name", "/content/",
        "handler", dict(
            "set", "None",
            ),
        ));
    append(dict(
        "name", "/media/",
        "handler", dict(
            "set", "None",
            ),
        ));
    append(dict(
        "name", "/",
        "access", dict( # by default, block all
            "deny", list("all"),
            "satisfy", "Any",
            "order", list("allow", "deny"),
            ),
        "limit", dict( # do not allow PUT and DELETE of ES data via kibana interface
            "name", list("PUT", "DELETE"),
            "access", dict(
                "order", list("allow", "deny"),
                "deny", list("all"),
                ),
            ),
        ));
};

"wsgi/importscript" = dict(
    "path", "/usr/share/graphite/graphite-web.wsgi",
    "process", "%{GLOBAL}",
    "application", "%{GLOBAL}",
);
