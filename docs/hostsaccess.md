### NAME

hostsaccess: NCM component to control `/etc/hosts.allow` and hosts.deny files

### DESCRIPTION

The _hostsaccess_ component manages the configuration files `/etc/hosts.allow`
and `/etc/hosts.deny`.  Few checks are done on the given configuration to 
allow all of the supported wildcarding. 

### RESOURCES

#### `/software/components/hostsaccess/allow`

A list where each entry consists of a named list with the keys: daemon
and host.  Both of the keys take strings as values and hence can
support the full wildcarding syntax.  These entries are allowed to
access the daemon. 

NOTE: The daemon name MUST be encoded with the pan escape()
function. This allows daemon lists to be used in the specification. 

#### `/software/components/hostsaccess/deny`

A list where each entry consists of a named list with the keys: daemon
and host.  Both of the keys take strings as values and hence can
support the full wildcarding syntax.  These entries are denied access
to the daemon. 

NOTE: The daemon name MUST be encoded with the pan escape()
function. This allows daemon lists to be used in the specification. 

### EXAMPLE

"/software/components/hostsaccess/allow" = push(nlist("daemon","slapd",
                                                 "host","127.0.0.1"));
