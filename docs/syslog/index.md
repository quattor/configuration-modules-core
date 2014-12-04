### NAME

NCM::syslog - adding entries and editing `/etc/syslog.conf`

### SYNOPSIS

- Configure()
- Unconfigure()

### RESOURCES

- `/software/components/syslog/active` : boolean

    activates/deactivates the component.

- `/software/components/syslog/fullcontrol` : boolean

    determines whether component has full control over `/etc/syslog.conf`, eventually erasing
    entries from other sources, or whether entries from other sources are kept

- `/software/components/syslog/syslogdoptions` : string

    Options for syslogd (/etc/sysconfig/syslog)

- `/software/components/syslog/syslogdoptions` : string

    Options for the klogd (/etc/sysconfig/syslog)

- `/software/components/syslog/config`/

    The configuration items 

### DEPENDENCIES

#### Components to be run before:

none.

#### Components to be run after:

none.

### BUGS

none known.

Ulrich Schwickerath <>

### SEE ALSO

ncm-ncd(1), sysklogd(8)
