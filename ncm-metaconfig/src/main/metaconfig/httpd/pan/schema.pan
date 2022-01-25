declaration template metaconfig/httpd/schema;


include 'pan/types';
include 'components/accounts/functions';

type httpd_sslprotocol = choice("all", "-SSLv3", "-TLSv1", "TLSv1", "-TLSv1.1", "TLSv1.1", "TLSv1.2", "TLSv1.3");

type httpd_ciphersuite = choice("TLSv1", "ECDHE-ECDSA-CHACHA20-POLY1305", "ECDHE-RSA-CHACHA20-POLY1305",
    "ECDHE-ECDSA-AES128-GCM-SHA256", "ECDHE-RSA-AES128-GCM-SHA256", "ECDHE-ECDSA-AES256-GCM-SHA384",
    "ECDHE-RSA-AES256-GCM-SHA384", "DHE-RSA-AES128-GCM-SHA256", "DHE-RSA-AES256-GCM-SHA384",
    "ECDHE-ECDSA-AES128-SHA256", "ECDHE-RSA-AES128-SHA256", "ECDHE-ECDSA-AES128-SHA", "ECDHE-RSA-AES256-SHA384",
    "ECDHE-RSA-AES128-SHA", "ECDHE-ECDSA-AES256-SHA384", "ECDHE-ECDSA-AES256-SHA", "ECDHE-RSA-AES256-SHA",
    "DHE-RSA-AES128-SHA256", "DHE-RSA-AES128-SHA", "DHE-RSA-AES256-SHA256", "DHE-RSA-AES256-SHA",
    "ECDHE-ECDSA-DES-CBC3-SHA", "ECDHE-RSA-DES-CBC3-SHA", "EDH-RSA-DES-CBC3-SHA", "AES128-GCM-SHA256",
    "AES256-GCM-SHA384", "AES128-SHA256", "AES256-SHA256", "AES128-SHA", "AES256-SHA", "DES-CBC3-SHA", "!RC4",
    "!LOW", "!aNULL", "!eNULL", "!MD5", "!EXP", "!3DES", "!IDEA", "!SEED", "!CAMELLIA", "!DSS");

# These are the settings for old clients, see https://access.redhat.com/articles/1467293 for stricter values.
type httpd_nss_protocol = string with match(SELF, '^(TLSv1\.[012]|SSLv3)$')
    || error("Use a modern cipher suite, for Pete's sake! see https://access.redhat.com/articles/1467293");

# only allow -(bad ciphers) and +(good ciphers) where good ciphers are from https://access.redhat.com/articles/1467293
# minues rc4, since the Bar Mitzvah attack
type httpd_nss_cipherstring = string with match(SELF, '^(-(rsa_3des_sha|rsa_des_56_sha|rsa_des_sha|rsa_null_md5|' +
    'rsa_null_sha|rsa_rc2_40_md5|rsa_rc4_128_md5|rsa_rc4_40_md5|rsa_rc4_56_sha|fortezza|fortezza_rc4_128_sha|' +
    'fortezza_null|fips_des_sha|fips_3des_sha|rsa_rc4_128_sha))|' +
    '(\+(ecdh_ecdsa_aes_128_sha|ecdh_ecdsa_aes_256_sha|ecdhe_ecdsa_aes_128_gcm_sha_256|ecdhe_ecdsa_aes_128_sha|' +
    'ecdhe_ecdsa_aes_128_sha_256|ecdhe_ecdsa_aes_256_gcm_sha_384|ecdhe_ecdsa_aes_256_sha|ecdhe_ecdsa_aes_256_sha_384|' +
    'ecdhe_rsa_aes_128_gcm_sha_256|ecdhe_rsa_aes_128_sha|ecdhe_rsa_aes_128_sha_256|ecdhe_rsa_aes_256_gcm_sha_384|' +
    'ecdhe_rsa_aes_256_sha|ecdhe_rsa_aes_256_sha_384|ecdh_rsa_aes_128_sha|ecdh_rsa_aes_256_sha|' +
    'rsa_aes_128_gcm_sha_256|rsa_aes_128_sha|rsa_aes_256_gcm_sha_384|rsa_aes_256_sha))$');

type httpd_protocols = choice("h2", "h2c", "http/1.1");

@documentation{
    Either all Options must start with + or -, or no Option may.
}
type httpd_option_plusminus_none = string[] with {
    if(length(SELF) < 2) {
        return(true);
    };

    plusminus = match(SELF[0], '^(\+|-)');
    foreach(idx; opt; SELF) {
        pm = match(opt, '^(\+|-)');
        if (to_long(plusminus) != to_long(pm)) {
            error(format('Either all options must start with + or -, or no option may: got %s compared with first %s',
                opt, SELF[0]));
        };
    };
    true;
};

type httpd_gssapi_credstore = string with match(SELF, '^((client_)?keytab|ccache:(FILE|DIR|KCM|KEYRING|MEMORY)):');

type httpd_gssapi_allowed_mech = string with match(SELF, '^(krb5|iakerb|ntlmssp)');

@documenation{
    Configure mod_gssapi, the mod_krb_auth replacement
    https://github.com/modauthgssapi/mod_auth_gssapi
}
type httpd_gssapi = {
    'sslonly' ? boolean
    'localname' ? boolean
    'connectionbound' ? boolean
    'signalpersistentauth' ? boolean
    'usesessions' ? boolean
    'sessionkey' ? string with match(SELF, '^key:')
    'credstore' ? httpd_gssapi_credstore[]
    'delegccachedir' ? string
    'uses4u2proxy' ? boolean
    'basicauth' ? boolean
    'allowedmech' ? httpd_gssapi_allowed_mech[]
    'basicauthmech' ? httpd_gssapi_allowed_mech[]
    @{for json nameattribute, use empty string as value}
    'nameattributes' ? string{}
};

type httpd_kerberos = {
    "keytab" : string # this becomes krb5keytab (but dicts can't start with digits)
    "methodnegotiate" : boolean
    "methodk5passwd" : boolean
    "servicename" : string
    "authrealms" : string[]
    "savecredentials" : boolean = false
};

@{OpenID Connect configuration for mod_auth_openidc
    https://github.com/pingidentity/mod_auth_openidc
}
type httpd_oidc = {
    "claimprefix" : string = "OIDC-"
    "responsetype" : string[]
    "scope" : string[]
    "clientid" : string(1..)
    "clientsecret" : string(1..)
    "cryptopassphrase" : string(1..)
    "redirecturi" : type_absoluteURI

    @{typically the SERVICE/.well-known/openid-configuration.
      If not configured, then the other provider fields must be provided}
    "providermetadataurl" ? type_absoluteURI

    "providerissuer" ? string
    "providerauthorizationendpoint" ? type_absoluteURI
    "providertokenendpoint" ? type_absoluteURI
    "providertokenendpointauth" ? type_absoluteURI
    "provideruserinfoendpoint" ? type_absoluteURI
    "providerjwksuri" ? type_absoluteURI
} with {
    if (!exists(SELF['providermetadataurl'])) {
        provs = list('issuer', 'authorizationendpoint', 'tokenendpoint',
                        'tokenendpointauth', 'userinfoendpoint', 'jwksuri');
        foreach (i; prov; provs) {
            if (!exists(SELF["provider" + prov])) {
                error("oidc attribute provider%s must be configured when providermetadataurl is absent", prov);
            };
        };
    };
    true;
};

type httpd_shibboleth = {
    "useheaders" ? boolean
    "requestsetting" ? string[]
};

type httpd_log_custom = {
    "location" : string
    "name" : string # this should be an existing format
};

type httpd_log_format = {
    # logformat "expr" name
    "expr" : string
    "name" : string
    "type" : choice('', 'error') = ''
};

type httpd_log = {
    "error" ? string
    "transfer" ? string
    "level" ? string with match(SELF, "^(debug|info|notice|warn|error|crit|alert|emerg)$")
    "format" ? httpd_log_format[]
    "custom" ? httpd_log_custom[]
};

type httpd_icon_add = {
    "icon" : string
    "names" : string[]
};

type httpd_icon = {
    "default" ? string
    "add" ? httpd_icon_add[]
    "addbytype" ? httpd_icon_add[]
    "addbyencoding" ? httpd_icon_add[]
};

type httpd_lang_add = {
    "lang" : string
    "names" : string[]
};

type httpd_lang = {
    "priority" ? string[]
    "forcepriority" ? string[]
    "default" ? string
    "add" ? httpd_lang_add[]
};

type httpd_setenvif = {
    "attribute" : string
    "regex" : string
    "variables" : string[]
    "quotes" : string = '"'
};

type httpd_env = {
    "if" ? httpd_setenvif[]
    "set" ? string{}
    "unset" ? string[]
    "pass" ? string[]
};

type httpd_ssl_nss_shared = {
    "passphrasehelper" ? string # eg /usr/sbin/nss_pcache
    "sessioncachetimeout" ? long
    "randomseed" ? string[][]
    "verifyclient" ? string with match(SELF, "^(require|none|optional|optional_no_ca)$")
    "require" ? string
    "options" ? httpd_option_plusminus_none
    "requiressl" ? boolean
    "passphrasedialog" ? string with match(SELF, '^(builtin|(exec|file):/.*)$')
};

type httpd_nss_global = {
    include httpd_ssl_nss_shared
    "sessioncachesize" ? long
    "session3cachetimeout" ? long
    "renegotiation" ? boolean
    "requiresafenegotiation" ? boolean
};

type httpd_ssl_global = {
    include httpd_ssl_nss_shared
    "sessioncache" ? string
    "mutex" ? string with match(SELF, '^(default)$')
    "cryptodevice" ? string[]

    "certificatefile" ? string
    "certificatekeyfile" ? string
    "certificatechainfile" ? string
    "cacertificatepath" ? string
    "cacertificatefile" ? string
    "carevocationfile" ? string
    "carevocationpath" ? string
    "carevocationcheck" ? choice("chain", "leaf", "none")

    "verifydepth" ? long

    "usestapling" ? string with match(SELF, '^(on|off)$')
    "staplingrespondertimeout" ? long
    "staplingreturnrespondererrors" ? string with match(SELF, '^(on|off)$')
    "staplingcache" ? string with match(SELF, '^shmcb:/var/run/ocsp\([0-9]+\)$')
};

type httpd_ssl_nss_vhost = {
    "engine" : boolean = true
};

type httpd_nss_vhost = {
    include httpd_nss_global
    include httpd_ssl_nss_vhost

    "protocol" : httpd_nss_protocol[] = list("TLSv1.0", "TLSv1.1", "TLSv1.2")
    "ciphersuite" : httpd_nss_cipherstring[] = list('+rsa_aes_128_sha', '+rsa_aes_256_sha', '+ecdhe_rsa_aes_256_sha',
        '+ecdhe_rsa_aes_128_sha', '+ecdh_rsa_aes_256_sha', '+ecdh_rsa_aes_128_sha', '+ecdhe_ecdsa_aes_256_sha',
        '+ecdhe_ecdsa_aes_128_sha', '+ecdh_ecdsa_aes_256_sha', '+ecdh_ecdsa_aes_128_sha')

    "nickname" : string
    "eccnickname" ? string
    "certificatedatabase" : string
    "dbprefix" ? string

    "ocsp" ? boolean
    "ocspdefaultresponder" ? string
    "ocspdefaulturl" ? string
    "ocspdefaultname" ? string
};

type httpd_ssl_vhost = {
    include httpd_ssl_global
    include httpd_ssl_nss_vhost
    "protocol" : httpd_sslprotocol[] = list("TLSv1")
    "ciphersuite" : httpd_ciphersuite[] = list("TLSv1")
    "honorcipherorder" ? string with match(SELF, '^(on|off)$')
    "compression" ? boolean
    "sessiontickets" ? boolean
};

type httpd_directory_allowoverride = string with match(SELF, '^(All|None|Options|FileInfo|AuthConfig|Limit)$');
type httpd_acl_order = string with match(SELF, "^(allow|deny)$");

type httpd_acl = {
    "order" ? httpd_acl_order[]
    "allow" ? type_network_name[]
    "deny" ? type_network_name[]
    "allowoverride" ? httpd_directory_allowoverride[]
    "satisfy" ? string with match(SELF, "^(All|Any)$")
};

@documentation{
    authz a.k.a. Require type. the keys are possible providers, each with their own syntax

}
type httpd_authz = {
    "all" ? string with match(SELF, '^(granted|denied)$')
    "valid-user" ? string # value of string is ignored
    "user" ? string[]
    "group" ? string[]
    "ip" ? type_network_name[]
    "env" ? string[]
    "method" ? string[]
    "expr" ? string
    "negate" ? boolean # not for each provider defined here
};

type httpd_limit_value = string with match(SELF, '^GET|POST|PUT|DELETE|CONNECT|OPTIONS|PATCH|PROPFIND|PROPPATCH|' +
    'MKCOL|COPY|MOVE|LOCK|UNLOCK$');

type httpd_limit = {
    "name" : httpd_limit_value[]
    "except" : boolean = false
    "access" ? httpd_acl # provided via mod_access_compat on 2.4
    "authz" ? httpd_authz[] # 2.4 only
};

type httpd_proxy_passreverse = {
    "path" ? string
    "url" : string
};

type httpd_proxy_pass = {
    "match" ? boolean # match is implied when regex is set; but you can have match without regex
    "regex" ? string
    "url" ? string
    "data" ? string{}
};

type httpd_proxy_set = {
    "url" ? string
    "data" ? string{}
};

type httpd_proxy = {
    "requests" ? boolean = false
    "set" ? httpd_proxy_set
    "pass" ? httpd_proxy_pass[]
    "passreverse" ? httpd_proxy_passreverse[]
};

type httpd_proxy_directive = {
    "name" : string
    "match" : boolean = false
    "proxy" ? httpd_proxy
};

type httpd_auth_require = {
    # require type who.join(' ')
    "type" : string with match(SELF, '^(valid-user|user|group|shibboleth|all)$')
    "who" ? string[]
};

type httpd_name_virtual_host = {
    "ip" : type_ip
    "port" ? type_port
};

type httpd_auth_type = choice("None", "Basic", "Kerberos", "Shibboleth", "GSSAPI", "openid-connect", "CAS");

type httpd_auth = {
    "name": string
    "require" : httpd_auth_require = dict('type', 'valid-user')
    "userfile" ? string
    "groupfile" ? string
    "basicprovider" ? choice('file', 'irods')
    "type" : httpd_auth_type = "Basic"
};

@{ Hostname and port of the iRODS server to connect to. @}
type davrods_server = {
    "host" : type_fqdn
    "port" : type_port
};

type davrods_anonymous = {
    "user" : string
    "password" : string
};

@{ Davrods plugin configuration @}
type httpd_davrods = {
    "Dav" : choice('davrods-locallock', 'davrods-nolocks') = 'davrods-locallock'
    "EnvFile" : string
    "Server" : davrods_server
    "Zone" : string
    "AuthScheme" : choice('Native', 'PAM') = 'Native'
    "AnonymousMode" ? choice('on', 'off') # off
    "AnonymousLogin" ? davrods_anonymous
    "DefaultResource" ? string
    "ExposedRoot" ? string with match(SELF, '^(/.*|User|Home|Zone)$')
    "TxBufferKbs" ? long
    "RxBufferKbs" ? long
    "TmpfileRollback" ? choice('on', 'off')
    "LockDB" ? string
    "HtmlHead" ? string
    "HtmlHeader" ? string
    "HtmlFooter" ? string
};

type httpd_file = {
    "name" : string
    "regex" : boolean = false # name is regex (i.e. add ~)
    "quotes" : string = '"'
    "options" ? httpd_option_plusminus_none = list("-indexes")
    "enablesendfile" ? boolean
    "lang" ? httpd_lang
    "ssl" ? httpd_ssl_global
    "nss" ? httpd_nss_global
    "auth" ? httpd_auth
    "kerberos" ? httpd_kerberos
    "shibboleth" ? httpd_shibboleth
    "gssapi" ? httpd_gssapi
    "access" ? httpd_acl # provided via mod_access_compat in 2.4
    "authz" ? httpd_authz[] # 2.4 only
};

type httpd_rewrite_cond = {
    "test" : string
    "pattern" : string
};

type httpd_rewrite_rule = {
    "conditions" ? httpd_rewrite_cond[]
    "regexp" : string
    "destination" : string
    "flags" : string[] = list() # empty list will generate empty string ([] is invalid)
};

type httpd_rewrite_map = {
    "name" : string
    "type" : string with match(SELF, '^(txt|rnd|dbm|int|prg|dbd|fastdbd)$')
    "source" : string
};

type httpd_rewrite_option = string with match(SELF, '^(Inherit|InheritBefore|AllowNoSlash|AllowAnyURI|MergeBase)$');

type httpd_rewrite = {
    "engine" : boolean = true
    "base" ? string
    "rules" ? httpd_rewrite_rule[]
    "maps" ? httpd_rewrite_map[]
    "options" ? httpd_rewrite_option[]
};

type httpd_redirect = {
    "status" ? long(100..599)  # a valid apache status, default is 302
    "path" : string with match(SELF, '^/')
    "url" ? type_URI
} with {
    status = if (exists(SELF['status'])) SELF['status'] else 302;
    if (status >= 300 && status <= 399) {
        if (!exists(SELF['url'])) {
            error("redirect %s: url must be present with status 3XX", SELF['path']);
        };
    } else {
        if (exists(SELF['url'])) {
            error("redirect %s: url must not be present with status not 3XX", SELF['path']);
        };
    };
    true;
};

type httpd_perl_handler = {
    "responsehandler" : string
};

type httpd_wsgi_importscript = {
    "path" : string
    "process" ? string
    "application" ? string
};

type httpd_wsgi_daemonprocess = {
    "name" : string
    @{converted in list of key=value}
    "options" ? string{}
};

type httpd_wsgi_common = {
    "applicationgroup" ? string
    "daemonprocess" ? httpd_wsgi_daemonprocess
    "importscript" ? httpd_wsgi_importscript # isn't supposed to be available for vhost?
    "processgroup" ? string
    "passauthorization" ? choice('on', 'off')
};

type httpd_wsgi_vhost = {
    include httpd_wsgi_common
};

type httpd_wsgi_server = {
    include httpd_wsgi_common
    'socketprefix' ? string
};

type httpd_listen = {
    "port" : long
    "name" ? string
    "protocol" ? string
};

type httpd_passenger_vhost = {
    "maxinstances" ? long
    "maxinstancesperapp" ? long
    "mininstances" ? long
    "user" ? string
    "group" ? string
};

type httpd_passenger = {
    include httpd_passenger_vhost
    "ruby" : string = "/usr/bin/ruby"
    "root" : string = "/usr/share/rubygems/gems/passenger-latest"
    "maxpoolsize" : long = 6
};

type httpd_rails = {
    "baseuri" : string[] = list("/rails")
    "env" ? string
};

type httpd_shared = {
    "documentroot" ? string = '/does/not/exist'
    "hostnamelookups" : boolean = false
    "servername" ? string with is_hostport(SELF) || SELF == 'null'
    "limitrequestbody" ? long(0..)
};

type httpd_encoding = {
    "mime" : string
    "extensions" : string[]
};

type httpd_alias = {
    "url" : string
    "destination" : string
    "type" : string = "" with match(SELF, '^(|script|wsgiscript)$')
};

type httpd_module_name = string with match(SELF, '^[.\-/\w]+$');

type httpd_module = {
    "name" : httpd_module_name
    "path" : string
};

type httpd_handler_add = {
    # addhandler name target.join(' ')
    "name" : string
    "target" : string[]
};

type httpd_handler = {
    "set" ? string
    "add" ? httpd_handler_add[]
};

type httpd_type_add = {
    # addtype name target.join(' ')
    "name" : string
    "target" : string[]
};

type httpd_type = {
    "default" ? string
    "config" ? string
    "add" ? httpd_type_add[]
};

type httpd_outputfilter_add = {
    # addoutputfilter name target.join(' ')
    "name" : string
    "target" : string[]
};

type httpd_outputfilter = {
    "add" ? httpd_outputfilter_add[]
};

type httpd_perl_vhost = {
    "modules" : string[]
    "options" : string[] = list("+Parent")
    "switches" ? string[]
};

type httpd_browsermatch = {
    # -> browsermatch "match" names.join(' ')
    "match" : string
    "names" : string[]
};

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
    "wsgi" ? httpd_wsgi_vhost
    "davrods" ? httpd_davrods
    "files" ? httpd_file[]
};

type httpd_vhost_ip = string with is_ip(SELF) || SELF == '*';

type httpd_header = {
    "name" : string
    "action" : choice('add', 'append', 'echo', 'edit', 'edit*', 'merge', 'set', 'setifempty', 'unset', 'note')
    "value" : string
    "quotes" : string = '"'
    "always" ? boolean
};

type httpd_serveralias = string with match(SELF, '^[\w.*]+$');  # serveralias supports wildcards

type httpd_vhost = {
    include httpd_shared

    "port" : type_port
    "ip" ? httpd_vhost_ip[]
    "serveralias" ? httpd_serveralias[]
    "ssl" ? httpd_ssl_vhost
    "nss" ? httpd_nss_vhost
    "locations" ? httpd_directory[]
    "files" ? httpd_file[]
    "aliases" ? httpd_alias[]
    "directories" ? httpd_directory[]
    "rewrite" ? httpd_rewrite
    "redirect" ? httpd_redirect[]
    "perl" ? httpd_perl_vhost
    "wsgi" ? httpd_wsgi_vhost
    "log" ? httpd_log
    "env" ? httpd_env
    "rails" ? httpd_rails
    "oidc" ? httpd_oidc
    "proxies" ? httpd_proxy_directive[]
    "browsermatch" ? httpd_browsermatch[]
    "passenger" ? httpd_passenger_vhost
    "header" ? httpd_header[]
    "protocols" ? httpd_protocols[]
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
    "servertokens" : string = "Prod"
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
    "serversignature" : boolean = false
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

    "userdir" ? string with match(SELF, "^(disabled|public_html)$")

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
    "global" : httpd_global_system = dict()
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
    "includes" : string[] = list("conf.d/*.conf")
    "includesoptional" ? string[]
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
    "locations" ? httpd_directory[]
    "wsgi" ? httpd_wsgi_server
};
