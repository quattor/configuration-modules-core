### NAME

NCM::named - NCM named configuration component

### DESCRIPTION

NCM component allowing to copy the named server configuration (/etc/named.conf) file from a reference location and/or configure the resolver configuration file (/etc/resolv.conf).

If named is started on the machine, localhost (127.0.0.1) is added as the first server in resolver configuration file.

### RESOURCES

#### `/software/components/named/start` : boolean (optional)

Enable/Start or Disable/Stop named server. If undefined, nothing is done.

#### `/software/components/named/configfile` : string (optional)

Reference file location for named configuration file. Existing (/etc/named.conf), if any, will be replaced.
'configfile' is mutually exclusive with 'serverConfig'.

#### `/software/components/named/serverConfig` : string (optional)

Content of named configuration file (/etc/named.conf). 'serverConfig' is mutually exclusive with 'configfile'.

#### `/software/components/named/servers` : list of hosts

Ordered list of named servers to use in (/etc/resolv.conf). If named server is started, localhost (127.0.0.1) will be added first.

#### `/software/components/named/options` : list of options

Ordered list of named options to use in (/etc/resolv.conf).

`/etc/resolv.conf` is updated : everything except 'nameserver' lines are preserved. All the 'nameserver' lines are replaced by information in this option, if present.

### DEPENDENCIES

None.

### BUGS

None known.

Michel Jouvin <>

### SEE ALSO

ncm-ncd(1), named(8)
