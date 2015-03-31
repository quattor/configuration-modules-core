declaration template metaconfig/carbon-relay-ng/schema;

include 'pan/types';

@documentation{
    blacklist all matching metrics
}
type carbon_relay_ng_addblack = {
    'match' : string
};

@documentation{
    route options
    prefix=str   only take in metrics that have this prefix
    sub=str      only take in metrics that match this substring
    regex=regex  only take in metrics that match this regex (expensive!)
}
type carbon_relay_ng_addroute_opts = {
    'prefix' ? string
    'sub' ? string
    'regex' ? string
};

@documentation{
    route destination options
    the route options and 
    flush=int          flush interval in ms
    reconn=int         reconnection interval in ms
    pickle=true,false  pickle output format instead of the default text protocol
    spool=true,false   enable spooling for this endpoint
}
type carbon_relay_ng_addroute_dest_opts = {
    include carbon_relay_ng_addroute_opts
    'flush' ? long(0..)
    'reconn' ? long(0..)
    'pickle' ? boolean
    'spool' ? boolean
};

@documentation{
    route destination: addr and opts
}
type carbon_relay_ng_addroute_dest = {
    'addr' : type_hostport
    'opts' ? carbon_relay_ng_addroute_dest_opts
};

@documentation{
    route
}
type carbon_relay_ng_addroute = {
    'type' : string with match(SELF, '^(sendAllMatch|sendFirstMatch)$')
    'key' : string
    'opts' ? carbon_relay_ng_addroute_opts
    'dest' : carbon_relay_ng_addroute_dest[]
};

@documentation{
    Init are initialisation commands passed during startup. (No modification possible)
}
type carbon_relay_ng_init = {
    'addRoute' ? carbon_relay_ng_addroute
    'addBlack' ? carbon_relay_ng_addblack
};

@documentation{
    Configure the instrumentation section (i.e. where to send ti's own metrics)
}
type carbon_relay_ng_instrumentation = {
    'graphite_addr' : type_hostport = "localhost:2003"
    'graphite_interval' : long(0..) = 1000 # in ms
};

@documentation{
    Configure the carbon-relay-ng conifg file (typically /etc/carbon-relay-ng.ini)
}
type carbon_relay_ng_service = {
    'instance' : string = 'default'
    'listen_addr' : type_hostport = "0.0.0.0:2003"
    'admin_addr' : type_hostport = "0.0.0.0:2004"
    'http_addr' : type_hostport = "localhost:8081"
    'spool_dir' : string = "/var/spool/carbon-relay-ng"
    'log_level' : string = "notice" with match(SELF, '^(critical|error|warning|notice|info|debug)$')
    'init' : carbon_relay_ng_init[]
    'instrumentation' ? carbon_relay_ng_instrumentation
};
