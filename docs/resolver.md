### NAME

NCM::resolver - NCM resolver configuration component

### SYNOPSIS

- Configure()

    Sets up the resolv.conf (and optionally the dnscache configuration).
    If dnscache is used, then dnscache will be restarted on any change.
    If DNS resolution fails after making the change, then resolv.conf
    is left in it's previous state.
    Returns
    error in case of failure.

- Unconfigure()

    not available.

### RESOURCES

- `/software/components/resolver/active` : boolean

    activates/deactivates the component.

- `/software/componens/resolver/search` : list

    A list of strings to use for the resolver search path.

- `/software/components/resolver/servers` : list

    list of server addresses or hostnames. If these are
    hostnames, they will be resolved before the resolver 
    configuration is modified.

- `/software/components/resolver/dnscache` : boolean

    If true, then configure dnscache with the server list
    and point resolv.conf at the localhost. This will
    cause dnscache to be restarted. This implies that
    the dnscache package is available on the machine:
    this component does not enforce that.

### FILES MODIFIED

The component resolver modifies the following files:

- `/etc/resolv.conf`
- `/var/spool/dnscache/servers`/@

### DEPENDENCIES

#### Components to be run before:

none.

#### Components to be run after:

none.

### EXAMPLES

"/software/components/resolver/active" = true;
"/software/components/resolver/search" = list("ms.com");
"/software/components/resolver/servers" = list("server1.ms.com");
"/software/components/resolver/dnscache" = true;

### BUGS

none known.

### SEE ALSO

ncm-ncd(1)
