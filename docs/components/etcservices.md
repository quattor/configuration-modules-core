### NAME

NCM::etcservices -  `/etc/services` configuration component

### DESCRIPTION

The services file  is a local source of information  regarding  each  service  available through the Internet.

### SYNOPSIS

- Configure()

    Configure `/etc/services` entries

- Unconfigure()

    Not implemented

### RESOURCES

- `/software/components/etcservices/active` : boolean

    activates/deactivates the component.

- `/software/components/etcservices/entries`

    The services file contains an entry for each  service.  Each entry has the form:
     service-name   port/protocol   aliases
    service-name: This is the official Internet service name.
    port/protocol: This field is composed of the port number and protocol through  which  the service is provided.
    aliases: This is a list of alternate names by which the service might be requested.

### DEPENDENCIES

#### Components to be run before:

dns.

#### Components to be run after:

none.
