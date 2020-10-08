object template davrods;

include 'metaconfig/httpd/schema';

bind "/software/components/metaconfig/services/{/etc/httpd/conf.d/davrods.conf}/contents" = httpd_vhosts;

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/davrods.conf}";
"module" = "httpd/2.4/generic_server";
"daemons/httpd" = "restart";

variable HTTPD_OS_FLAVOUR ?= 'el7';
variable FULL_HOSTNAME = 'myhost.domain';
variable HOSTNAME = 'myhost';
variable DB_IP = dict(HOSTNAME, '1.2.3.4');

"/software/components/metaconfig/services/{/etc/httpd/conf.d/davrods.conf}/contents/vhosts/davrodspub" = {
    base = create(format('struct/ssl_conf_%s', HTTPD_OS_FLAVOUR));

    pubvhost = create('struct/public_vhost');

    foreach(idx; val; list('certificatefile', 'certificatekeyfile', 'cacertificatefile')) {
        base['vhosts']['base']['ssl'][val] = pubvhost['ssl'][val];
    };

    base['vhosts']['base'];
};

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/davrods.conf}/contents";
"listen" = append(dict("port", 444));

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/davrods.conf}/contents/vhosts/davrodspub";
"ip/0" = DB_IP[HOSTNAME];
"port" = 444;
"servername" = FULL_HOSTNAME;

"locations/0" = dict(
        "name", "/",
        "directoryindex", list('disabled'),
);
prefix "locations/0/auth";
"name" = 'DAV';
"basicprovider" = 'irods';
"type" = "Basic";


prefix "locations/0/davrods";

"Dav" = 'davrods-locallock';
"EnvFile" = "/etc/irods/envfile";
"Server" = dict('host', "myserver.domain.org", 'port', 1247);
"Zone" = "irodszone";
"AuthScheme" = 'Native';
"AnonymousLogin" = dict('user' , 'me', 'password', 'moi');
"AnonymousMode" = 'on';
"DefaultResource" = 'resource1';
"ExposedRoot" = 'Home';

