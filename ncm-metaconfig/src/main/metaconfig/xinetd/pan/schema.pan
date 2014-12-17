declaration template metaconfig/xinetd/schema;

type xinetd_options_type = string with match(SELF,"^(RPC|INTERNAL|TCPMUX|TCPMUXPLUS|UNLISTED)$");

type xinetd_options_flags = string with match(SELF,"^(INTERCEPT|NORETRY|IDONLY|NAMEINARGS|NODELAY|KEEPALIVE|NOLIBWRAP|SENSOR|IPv4|IPv6|LABELED|REUSE)$");

type xinetd_options_ips = string; # TODO, write proper check for all possible combinations

type xinetd_options = {
    "disable" : boolean = false
    "wait" : boolean = true # true for udp/datagram , false for tcp/stream

    "id" ? string # default is service name

    "type" ? xinetd_options_type[]
    "flags" ? xinetd_options_flags[]
    "only_from" ? xinetd_options_ips[]
    "cps" : long[] = list(100, 2)

    "socket_type" : string with match(SELF,'^(stream|dgram|raw|seqpacket)$')
    "user" : string = 'root'
    "server" : string
    "protocol" : string with match(SELF,'^(udp|tcp)$') # actually, anything in /etc/protocols
    "server_args" ? string
    "group" ? string
    "instances" ? long(0..) # if not defined, it's UNLIMITED
    "per_source" : long = 11
};

type xinetd_conf = {
    "servicename" : string
    "options" : xinetd_options
};

