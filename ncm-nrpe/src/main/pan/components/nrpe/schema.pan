${componentschema}

include 'quattor/types/component';
include 'pan/types';

type component_nrpe_options = {
    @{The syslog facility that should be used for logging purposes.}
    'log_facility' : string = 'daemon'
    @{File in which the NRPE daemon should write it's process ID number.}
    'pid_file' : string = '/var/run/nrpe.pid'
    @{The port the daemon will listen to.}
    'server_port' : type_port = 5666
    @{Address that nrpe should bind to if you do not want nrpe to bind on all interfaces.}
    'server_address' ? string
    @{User the daemon will run as.}
    'nrpe_user' : string = 'nagios'
    @{Group the daemon will run as.}
    'nrpe_group' : string = 'nagios'
    @{List of hosts allowed to order the NRPE daemon to run commands.}
    'allowed_hosts' : type_hostname[]
    @{Whether or not the remote hosts are allowed to pass arguments to the
      commands offered by NRPE.}
    'dont_blame_nrpe' : boolean = false
    @{Optional prefix for every single command to be run (e.g. /usr/bin/sudo).}
    'command_prefix' ? string
    @{Whether or not debugging messages are logged to the syslog facility.}
    'debug' : boolean = false
    @{Timeout for commands, in seconds.}
    'command_timeout' : long = 60
    @{Timeout for connections, in seconds.}
    'connection_timeout' : long = 300
    @{Whether or not allow weak random number generation.}
    'allow_weak_random_seed' ? boolean = false
    @{Dict with the command lines to be run. Keys are the
      command identifiers. Check Nagios' documentation for more information
      on command definitions.}
    'command' : string{}  # Indexed by command name.
    @{List of external file names that should be included.}
    'include' ? string[]
    @{List of directory names that should be included.}
    'include_dir' ? string[]
};

type nrpe_component = {
    include structure_component
    'mode' : long = 0640
    'options' : component_nrpe_options
};

