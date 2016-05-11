declaration template metaconfig/perfsonar/bwctl/schema;

include 'pan/types';

type bwctl_client = {
    "iperf_port" ? type_port
    "control_timeout" : long(0..) = 7200
    "allow_unsync" : boolean = false
};

type bwctl_server = {
    include bwctl_client
    "user" : string = "bwctl"
    "group" : string = "bwctl"
    "nuttcp_port" : type_port
};

type bwctl_limitname = string with exists("/software/components/metaconfig/services/{/etc/bwctld/bwctld.limits}/contents/limit/" + SELF) ||
    error(SELF + " must be an existing bwctl limit specification (watch out for cyclic references!");

type bwctl_limit = {
    "parent" ? bwctl_limitname
    "duration" ? long(0..)
    "allow_tcp" ? boolean
    "allow_udp" ? boolean
    "bandwidth" ? long
    "allow_open_mode" ? boolean
};

type bwctl_assign = {
    "network" : type_network_name
    "restrictions" : bwctl_limitname
};

type bwctl_limits = {
    "assign" : bwctl_assign[]
    "limit" : bwctl_limit{}
};

