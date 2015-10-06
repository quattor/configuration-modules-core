declaration template metaconfig/httpd/types_composed;

type httpd_directory = {
    include httpd_file
    "rewrite" ? httpd_rewrite
    "handler" ? httpd_handler
    "outputfilter" ? httpd_outputfilter
    "perl" ? httpd_perl_handler
    "env" ? httpd_env
    "limit" ? httpd_limit
    "proxy" ? httpd_proxy
    "directoryindex" ? string[]
    "limitrequestbody" ? long(0..)
};

type httpd_vhost = {
    include httpd_shared

    "port" : type_port
    "ip" ? type_ip[]
    "ssl" ? httpd_ssl_vhost
    "nss" ? httpd_nss_vhost
    "locations" ? httpd_directory[]
    "files" ? httpd_file[]
    "aliases" ? httpd_alias[]
    "directories" ? httpd_directory[]
    "rewrite" ? httpd_rewrite
    "perl" ? httpd_perl_vhost
    "wsgi" ? httpd_wsgi_vhost
    "log" ? httpd_log
    "env" ? httpd_env
    "rails" ? httpd_rails
    "proxies" ? httpd_proxy_directive[]
};

# system wide settings
type httpd_global_shared = {
    include httpd_shared

    "directoryindex" ? string[]
    "wsgipythonpath" ? string
};

# server specific system wide only
type httpd_global_system = {
    include httpd_global_shared
    "servertokens" : string = "OS"
    "serverroot" : string = "/etc/httpd"
    "pidfile" : string = "run/httpd.pid"
    "timeout" : long = 60
    "keepalive" : boolean = false
    "maxkeepaliverequests" : long = 100
    "keepalivetimeout" : long = 15
    "extendedstatus" : boolean = false
    "user" : defined_user = "apache"
    "group" : defined_group = "apache"
    "serveradmin" : string = "root@localhost"
    "usecanonicalname" : boolean = false
    "accessfilename" : string = ".htaccess"
    "enablemmap" : boolean = true
    "enablesendfile" : boolean = true
    "serversignature" : boolean = true
    "indexoptions" : string[] = list("FancyIndexing", "VersionSort", "NameWidth=*", "HTMLTable", "Charset=UTF-8")
    "indexignore" : string[] = list(".??*", "*~", "*#", "HEADER*", "README*", "RCS", "CVS", "*,v", "*,t")
    "readmename" : string = "README.html"
    "headername" : string = "HEADER.html"
    "adddefaultcharset" : string = "UTF-8"

    "limitrequestfieldsize" ? long
    "traceenable" ? string with match(SELF, '^(on|off|extended)$')
};

type httpd_ifmodule_parameters = {
    "name" : string
    "directories" ? httpd_directory[]
    "type" ? httpd_type
    "outputfilter" ? httpd_outputfilter
    "log" ? httpd_log
    "aliases" ? httpd_alias[]
    "modules" ? httpd_module[]
    "startservers" ? long
    "minspareservers" ? long
    "maxspareservers" ? long
    "serverlimit" ? long
    "maxclients" ? long
    "maxrequestsperchild" ? long

    "minsparethreads" ? long
    "maxsparethreads" ? long
    "threadsperchild" ? long

    "userdir" ? string with match(SELF,"^(disabled|public_html)$")

    "davlockdb" ? string

    "mimemagicfile" ? string

    "directoryindex" ? string[]
};

type httpd_ifmodule = {
    include httpd_ifmodule_parameters
    "ifmodules" ? httpd_ifmodule_parameters[] # only depth 1 ?
};

# only for conf/httpd.conf
type httpd_global = {
    include httpd_includes
    "global" : httpd_global_system = nlist()
    "aliases" ? httpd_alias[]
    "modules" ? httpd_module[]
    "ifmodules" : httpd_ifmodule[]
    "directories" ? httpd_directory[]
    "files" ? httpd_file[]
    "log" ? httpd_log
    "icon" ? httpd_icon
    "lang" ? httpd_lang
    "browsermatch" ? httpd_browsermatch[]
    "handler" ? httpd_handler
    "type" ? httpd_type
    "outputfilter" ? httpd_outputfilter
    "listen" ? httpd_listen[]
};

# for conf.d/*.conf
type httpd_vhosts = {
    "global" ? httpd_global_shared
    "modules" ? httpd_module[]
    "vhosts" ? httpd_vhost{}
    "files" ? httpd_file[]
    "aliases" ? httpd_alias[]
    "directories" ? httpd_directory[]
    "encodings" ? httpd_encoding[]
    "listen" ? httpd_listen[]
    "handler" ? httpd_handler
    "ifmodules" ? httpd_ifmodule[]
    "type" ? httpd_type
    "env" ? httpd_env
    "ssl" ? httpd_ssl_global
    "nss" ? httpd_nss_global
    "passenger" ? httpd_passenger
    "namevirtualhost" ? httpd_name_virtual_host
};
