### NAME

NCM::nscd - NCM component to configure nscd

### SYNOPSIS

- Configure()

    Configures the name service caching daemon (nscd). See the `nscd.conf(5)` man page 
    or the CDB schema file for allowed options. Booleans have to be written as
    _yes_ or _no_ in the template, this is the way _nscd_ expects them.

### FILES

modifies `/etc/nscd.conf` and a temporary file in `/etc`.

Jan.I

### SEE ALSO

nscd(8), nscd.conf(5)
