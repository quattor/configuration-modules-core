object template keystone;

@{regenerate the queens keystone config}

include 'metaconfig/httpd/schema';

bind "/software/components/metaconfig/services/{/etc/httpd/conf.d/wsgi-keystone.conf}/contents" = httpd_vhosts;

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/wsgi-keystone.conf}";
"module" = "httpd/2.4/generic_server";
"daemons/httpd" = "restart";

prefix "contents";
"listen" = append(dict("port", 5000));
"listen" = append(dict("port", 35357));

"aliases" = append(dict("url", "/identity", "destination", "/usr/bin/keystone-wsgi-public"));
"aliases" = append(dict("url", "/identity_admin", "destination", "/usr/bin/keystone-wsgi-admin"));

"vhosts" = {
    data = dict(
        "ip", list("*"),
        "port", 5000,
        "limitrequestbody", 112 * 1024,
        "log", dict(
            "format", list(dict(
                "type", "error",
                "expr", "%{cu}t %M",
                "name", "", # must be empty
                )),
            "error", "/var/log/httpd/keystone.log",
            "custom", list(dict(
                "location", "/var/log/httpd/keystone_access.log",
                "name", "combined",
                )),
            ),
        "wsgi", dict(
            "passauthorization", "on",
            "processgroup", "keystone-public",
            "applicationgroup", "%{GLOBAL}",
            "daemonprocess", dict(
                "name", "keystone-public",
                "options", dict(
                    "processes", "5",
                    "threads", "1",
                    "user", "keystone",
                    "group", "keystone",
                    "display-name", "%{GROUP}",
                    ),
                ),
            ),
        "aliases", list(dict(
            "url", "/",
            "destination", "/usr/bin/keystone-wsgi-public",
            "type", "wsgiscript",
            )),
        "directories", list(dict(
            "name", "/usr/bin",
            "authz", list(dict("all", "granted")),
            )),
        );
    SELF['keystone'] = clone(data);

    data['port'] = 35357;
    data['wsgi']['processgroup'] = "keystone-admin";
    data['wsgi']['daemonprocess']['name'] = "keystone-admin";
    data['aliases'][0]['destination'] = "/usr/bin/keystone-wsgi-admin";
    SELF['keystoneadm'] = data;

    SELF;
};

"locations" = {
    data = dict(
        "name", "/identity",
        "handler", dict("set", "wsgi-script"),
        "options", list("+ExecCGI"),
        "wsgi", dict(
            "passauthorization", "on",
            "processgroup", "keystone-public",
            "applicationgroup", "%{GLOBAL}",
            ),
        );
    append(clone(data));

    data['name'] = "/identity_admin";
    data['wsgi']['processgroup'] = "keystone-admin";
    append(data);

    SELF;
};

# actually from horizon
"wsgi/socketprefix" = "run/wsgi";
"vhosts/keystone/header" = append(dict(
    'action', 'add',
    'name', 'Strict-Transport-Security',
    'value', 'max-age=15768000'
    ));
