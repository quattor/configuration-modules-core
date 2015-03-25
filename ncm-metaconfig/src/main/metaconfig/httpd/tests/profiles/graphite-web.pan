object template graphite-web;

include 'metaconfig/httpd/schema';

bind "/software/components/metaconfig/services/{/etc/httpd/conf.d/graphite-web.conf}/contents" = httpd_vhosts;

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/graphite-web.conf}";
"module" = "httpd/generic_server";
"daemon/0" = "httpd";

variable HTTPD_OS_FLAVOUR ?= 'el6';
variable FULL_HOSTNAME = 'myhost.domain';
variable HOSTNAME = 'myhost';
variable DB_IP = nlist(HOSTNAME, '1.2.3.4');

"/software/components/metaconfig/services/{/etc/httpd/conf.d/graphite-web.conf}/contents/vhosts/graphiteweb" = {
    base=create(format('struct/ssl_conf_%s', HTTPD_OS_FLAVOUR));
    
    pubvhost=create('struct/public_vhost');
    
    foreach(idx;val;list('certificatefile', 'certificatekeyfile', 'cacertificatefile')) {
        base['vhosts']['base']['ssl'][val] = pubvhost['ssl'][val];
    };    
    
    base['vhosts']['base'];
};

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/graphite-web.conf}/contents";
"listen" = append(nlist("port", 444));

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/graphite-web.conf}/contents/vhosts/graphiteweb";
"ip/0" = DB_IP[HOSTNAME];
"port" = 444;
"servername" = FULL_HOSTNAME;

"documentroot" = "/usr/share/graphite/webapp";
"log/level" = "info";
"log/error" = "logs/graphite-web_error_log";
"log/transfer" = null;
"log/custom" = list(nlist(
    "location", "logs/graphite-web_access_log", 
    "name", "combined"
));

"aliases" = {
    append(nlist(
        "url", "/media/",
        "destination", "/usr/lib/python2.6/site-packages/django/contrib/admin/media/",
        ));
    append(nlist(
        "url", "/",
        "destination", "/usr/share/graphite/graphite-web.wsgi",
        "type", "wsgiscript",
        ));
};    


"locations" = {
    append(nlist(
        "name", "/content/",
        "handler", nlist(
            "set", "None",
            ),
        ));
    append(nlist(
        "name", "/media/",
        "handler", nlist(
            "set", "None",
            ),
        ));
    append(nlist(
        "name", "/",
        "access", nlist( # by default, block all
            "deny", list("all"),
            "satisfy", "Any",
            "order", list("allow", "deny"),
            ),
        "limit", nlist( # do not allow PUT and DELETE of ES data via kibana interface
            "name", list("PUT", "DELETE"),
            "access", nlist(
                "order", list("allow", "deny"),
                "deny", list("all"),
                ),
            ),
        ));
};

"wsgi/importscript" = nlist(
    "path", "/usr/share/graphite/graphite-web.wsgi",
    "process", "%{GLOBAL}",
    "application", "%{GLOBAL}",
);
