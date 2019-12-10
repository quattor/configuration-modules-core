declaration template metaconfig/xinetd/schema;

type xinetd_options_type = choice("RPC", "INTERNAL", "TCPMUX", "TCPMUXPLUS", "UNLISTED");

type xinetd_options_flags = choice("INTERCEPT", "NORETRY", "IDONLY",
    "NAMEINARGS", "NODELAY", "KEEPALIVE", "NOLIBWRAP", "SENSOR", "IPv4", "IPv6",
    "LABELED", "REUSE");

type xinetd_options_ips = string; # TODO, write proper check for all possible combinations

type xinetd_options_log_on_success = choice("PID", "HOST", "USERID", "EXIT", "DURATION", "TRAFFIC");

type xinetd_options_log_on_failure = choice("HOST", "USERID", "ATTEMPT");

type xinetd_options = {
    "disable" : boolean = false
    "wait" : boolean = true # true for udp/datagram , false for tcp/stream

    "id" ? string # default is service name

    "type" ? xinetd_options_type[]
    "flags" ? xinetd_options_flags[]
    "only_from" ? xinetd_options_ips[]
    "cps" ? long[]
    "port" ? long(0..)

    "socket_type" : choice("stream", "dgram", "raw", "seqpacket")
    "user" : string = 'root'
    "server" ? string
    "protocol" ? choice("udp", "tcp") # actually, anything in /etc/protocols
    "server_args" ? string
    "group" ? string
    "instances" ? string with match(SELF, '^(UNLIMITED|\d+)$')
    "per_source" ? long
    "log_on_success" ? xinetd_options_log_on_success[]
    "log_on_failure" ? xinetd_options_log_on_failure[]
};

type xinetd_conf = {
    "servicename" : string
    "options" : xinetd_options
};

