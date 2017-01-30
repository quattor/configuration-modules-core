# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/nrpe/schema;

include 'quattor/schema';

type component_nrpe_options = {
    'log_facility' : string = 'daemon'
    'pid_file' : string = '/var/run/nrpe.pid'
    'server_port' : type_port = 5666
    'server_address' ? string
    'nrpe_user' : string = 'nagios'
    'nrpe_group' : string = 'nagios'
    'allowed_hosts' : type_hostname[]
    'dont_blame_nrpe' : boolean = false
    'command_prefix' ? string
    'debug' : boolean = false
    'command_timeout' : long = 60
    'connection_timeout' : long = 300
    'allow_weak_random_seed' ? boolean = false
    'command' : string{}  # Indexed by command name.
    'include' ? string[]
    'include_dir' ? string[]
};

type structure_component_nrpe = {
    include structure_component
    'mode' : long = 0640
    'options' : component_nrpe_options
};

bind '/software/components/nrpe' = structure_component_nrpe;
