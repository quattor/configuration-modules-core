declaration template metaconfig/haproxy/schema;

include 'pan/types';

@documentation {
    list of syslog facilities
}
type haproxy_service_global_logs = {
    '{/dev/log}' ? string[] = list('local0' , 'notice')
    '{127.0.0.1}' ? string[] = list('local2')
};

@documentation {
    Define the Global config options
}
type haproxy_service_global_config = {
    'tune.ssl.default-dh-param' ? long
    'user' : string = 'haproxy'
    'group' : string = 'haproxy'
    'maxconn' : long = 4000
    'daemon' : string = ''
    'pidfile' : string = '/var/run/haproxy.pid'
    'chroot' : string = '/var/lib/haproxy'
    'log-send-hostname' ? string

    'ssl-default-bind-ciphers' ? string_non_whitespace[]
    'ssl-default-bind-options' ? string[]
    'ssl-default-bind-ciphersuites' ? string_non_whitespace[]
    'ssl-default-server-ciphers' ? string_non_whitespace[]
    'ssl-default-server-options' ? string[]
    'ssl-default-server-ciphersuites' ? string_non_whitespace[]
    'ssl-dh-param-file' ? absolute_file_path
};

@documentation {
    options for the stats line in the Global section
}
type haproxy_service_global_stats = {
    'socket' : string = '/var/lib/haproxy/stats'
};

@documentation {
    The global section
}
type haproxy_service_global = {
    'logs' : haproxy_service_global_logs
    'config' : haproxy_service_global_config
    'stats' : haproxy_service_global_stats
};

@documentation {
    Configuration in the Default section
}
type haproxy_service_defaults_config = {
    'log' : string = 'global'
    'mode' ? choice("http", "tcp")
    'retries' : long = 3
    'maxconn' : long = 4000
    'option' ? string
};

@documentation {
    Timeouts in ms
}
type haproxy_service_timeouts = {
    'check' : long = 3500
    'queue' : long = 3500
    'connect' : long = 3500
    'client' : long = 10000
    'server' : long = 10000
    'client-fin' ? long(4000..)
    'server-fin' ? long(4000..)
    'tunnel' ? long(4000..)
};

@documentation {
    The Default Section
}
type haproxy_service_defaults = {
    'config' : haproxy_service_defaults_config
    'timeouts' : haproxy_service_timeouts
};


@documentation {
    options in the stats section
}
type haproxy_service_stats_options = {
    'enabled' ? string = ''
    'hide-version' : string = ''
    'uri' : string = '/'
    'refresh' : long = 5
};

@documentation {
    configuration in the stats section
}
type haproxy_service_stats = {
    'mode' : string = 'http'
    'options' ? haproxy_service_stats_options
};

@documentation {
    per proxy configuration
}
type haproxy_service_proxy_config = {
    'mode' : string
    'capture' ? string
    'cookie' ? string
    'rspidel' ? string
    'balance' : string
};

@documentation {
    options against the default server line in the proxy
}
type haproxy_service_proxy_defaultoptions = {
    'inter' : long = 2
    'downinter' : long = 5
    'rise' : long = 3
    'fall' : long = 2
    'slowstart' : long = 60
    'maxqueue' : long = 128
    'weight' : long = 100
};

@documentation {
    options to be added to each server in the proxy
}
type haproxy_service_proxy_serveroptions = {
    'cookie' ? string
};

@documentation {
    configuration of a proxy
}
type haproxy_service_proxy = {
    'name' : string
    'port' : type_port
    'binds' : string[]
    'config' : haproxy_service_proxy_config
    'options' ? string[]
    'defaultoptions' : haproxy_service_proxy_defaultoptions
    'servers' : dict
    'serveroptions' ? haproxy_service_proxy_serveroptions
    'timeouts' ? haproxy_service_timeouts
};

@documentation {
    configuration of a peer
}
type haproxy_service_peer = {
    @{Name of the peer host. Preferably in FQDN.}
    'name' : string
    @{Port to use to connect to peer.}
    'port' : type_port
    @{IP address of the peer.}
    'ip' : type_ip
};

@documentation {
    configuration of peers
}
type haproxy_service_peers = {
    'peers': haproxy_service_peer[]
};

@documentation {
    configuration of stick table
}
type haproxy_service_stick_table = {
    'type' : string
    'size' : string
    'peers' ? string
};

type haproxy_service_reqrep = {
    'pattern' : string
    'replace' : string
};

type haproxy_service_bind_server_params = {
    'ssl' ? boolean
    'ca-file' ? absolute_file_path
    @{combined cert and key in pem format}
    'crt' ? absolute_file_path
    @{interface to bind on}
    'interface' ? string
    @{enable the TLS ALPN extension}
    'alpn' ? string = "h2,http/1.1"
    @{interval in milliseconds between healthchecks}
    'inter' ? long
};

type haproxy_service_server_params = {
    include haproxy_service_bind_server_params
    @{enable health check}
    'check' ? boolean
    @{different health check port}
    'port' ? type_port
    'cookie' ? string
};

type haproxy_service_bind_params = {
    include haproxy_service_bind_server_params
};

type haproxy_service_bind = {
    'bind' : string with SELF == '*' || is_hostname(SELF) || is_absolute_file_path(SELF)
    'params' ? haproxy_service_bind_params
    'port' ? type_port
};

type haproxy_service_frontend_errorfile = {
    'code' : long(200..600)
    'filename' : absolute_file_path
};

type haproxy_service_frontend = {
    'acl' ? dict()
    'bind' : haproxy_service_bind[]
    'default_backend' : string
    'use_backend' ? string_trimmed[]
    'mode' ? choice("tcp", "http")
    'tcp-request' ? string[]
    'http-request' ? string[]
    'errorfile' ? haproxy_service_frontend_errorfile[]
};

type haproxy_service_backend_server = {
    'name' : string
    'ip' : type_ip
    'port' ? type_port
    'params' ? haproxy_service_server_params
};

@{configure 'http-check expect [!] match pattern'}
type haproxy_service_http_check = {
    'inverse' ? boolean
    'match' : choice('status', 'rstatus', 'string', 'rstring')
    'pattern' : string
};

type haproxy_service_backend = {
    'balance' ? choice('roundrobin', 'static-rr', 'leastconn', 'first', 'source', 'uri', 'url_param')
    'mode' ? choice("tcp", "http")
    'options' ? string[]
    'httpcheck' ? haproxy_service_http_check
    'tcpchecks' ? string[]
    'sticktable' ? haproxy_service_stick_table
    'stick' ? string
    'servers' : haproxy_service_backend_server[]
    'reqrep' ? haproxy_service_reqrep[]
    'http-request' ? string[]
    'acl' ? dict()
    'cookie' ? string
};

@documentation {
    haproxy config
    see documentation on www.haproxy.org
}
type haproxy_service = {
    'global' : haproxy_service_global
    'defaults' : haproxy_service_defaults
    'stats' ? haproxy_service_stats
    'peers' ? haproxy_service_peers{}
    'proxys' ? haproxy_service_proxy[]
    'frontends' ? haproxy_service_frontend{}
    'backends' ? haproxy_service_backend{}
} with {
    if (exists(SELF['frontends'])) {
        if (!exists(SELF['backends'])) {
            error('haproxy backends must be defined when frontends are defined');
        };
        foreach (fr; frd; SELF['frontends']) {
            if (exists(frd['default_backend'])) {
                if (!exists(SELF['backends'][frd['default_backend']])) {
                    error('default backend for frontend %s (data %s) does not exist', fr, frd);
                };
            };
        };
    };
    true;
};
