# ${license-info}
# ${developer-info}
# ${author-info}

declaration template metaconfig/nrpe/schema;

include 'pan/types';

@{Configuration options for Nagios Remote Plugin Executor (NRPE)}
type nrpe_service = {
    'log_facility' : string = 'daemon'
    'pid_file' : string = '/var/run/nrpe.pid'
    'server_port' : type_port = 5666
    'server_address' ? type_hostname
    'nrpe_user' : string = 'nagios'
    'nrpe_group' : string = 'nagios'
    'allowed_hosts' : type_hostname[]
    'dont_blame_nrpe' : boolean = false
    'command_prefix' ? string
    'debug' : boolean = false
    'command_timeout' : long(0..) = 60
    'connection_timeout' : long(0..) = 300
    'allow_weak_random_seed' ? boolean = false
    'command' : string{}  # Indexed by command name.
    'include' ? string[]
    'include_dir' ? string[]
};
