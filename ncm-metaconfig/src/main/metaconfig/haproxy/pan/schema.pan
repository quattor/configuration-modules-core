declaration template metaconfig/haproxy/schema;

include 'pan/types';

@documentation {
    list of syslog facilities
}
type haproxy_service_global_logs = {
    '{/dev/log}' : string[] = list('local0','notice')
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
};

@documentation {
    options for the stats line in the Global section
}
type haproxy_service_global_stats = {
    'socket' : string = '/var/lib/haproxy/stats'
};

@documentation {
    
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
    'mode' ? string
    'retries' : long = 3
    'maxconn' : long = 4000
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
};

@documentation {

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

}
type haproxy_service = {
    'global' : haproxy_service_global
    'defaults' : haproxy_service_defaults
    'stats' ? haproxy_service_stats
    'proxys' ? haproxy_service_proxy[]
};

