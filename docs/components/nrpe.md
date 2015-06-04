### DESCRIPTION

The _nrpe_ component manages the NRPE daemon, which executes Nagios
plugins on remote hosts. The NRPE service can be run under xinetd or
as a stand-alone daemon. This component only supports the stand-alone
way.

### COMPONENT STRUCTURE

All fields are required (but most have sensible defaults unless otherwise stated).

- `/software/components/nrpe/options/allowed_hosts : type_hostname[]`

    List of hosts allowed to order the NRPE daemon to run commands.

    Must be specified, no default is provided.

- `/software/components/nrpe/options/command : string {}`

    Named list with the command lines to be run. It is indexed with the
    command identifiers. Check Nagios' documentation for more information
    on command definitions.

    Must be specified, no default is provided.

- `/software/components/nrpe/options/log_facility : string`

    The syslog facility that should be used for logging purposes.

- `/software/components/nrpe/options/pid_file : string`

    File in which the NRPE daemon should write it's process ID number.

- `/software/components/nrpe/options/server_port : type_port`

    The port the daemon will listen to.

- `/software/components/nrpe/options/server_address ? string`

    Address that nrpe should bind to if you do not want nrpe to bind on all interfaces.

    Optional field.

- `/software/components/nrpe/options/nrpe_user : string`

    User the daemon will run as. For instance, 'nagios'.

- `/software/components/nrpe/options/nrpe_group : string`

    Group the daemon will run as. For instance, 'nagios'.

- `/software/components/nrpe/options/dont_blame_nrpe : boolean`

    Whether or not the remote hosts are allowed to pass arguments to the
    commands offered by NRPE. It is false by default, so arguments are not
    allowed for security reasons.

- `/software/components/nrpe/options/command_prefix ? string`

    Optional prefix for every single command to be run. For instance,
    "/usr/bin/sudo"

    Optional field.

- `/software/components/nrpe/options/debug : boolean`

    Whether or not debugging messages are logged to the syslog facility.

- `/software/components/nrpe/options/command_timeout : long`

    Timeout for commands, in seconds.

- `/software/components/nrpe/options/connection_timeout : long`

    Timeout for connections, in seconds.

- `/software/components/nrpe/options/allow_weak_random_seed : boolean`

    Whether or not allow weak random number generation.

- `/software/components/nrpe/options/include : string []`

    List of external file names that should be included.

- `/software/components/nrpe/options/include_dir : string []`

    List of directory names that should be included.

### SEE ALSO

http://nagios.sourceforge.net/docs/3\_0/toc.html
