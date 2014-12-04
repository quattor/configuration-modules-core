---
layout: documentation
title: libvirtd
category: documentation
subcategory: components
menu: 'components.md'
---
### DESCRIPTION

The _libvirtd_ component manages the configuration of the
the libvirtd daemon.

### CONFIGURATION PARAMETERS

The base path for all of the configuration parameters is
    `/software/components/libvirtd.`  The following sections describe the
    elements that are permitted directly below this base path.  With
    further parameters described in each section.  All parameters are
    optional.  Except the configuration file location. 

#### libvirtd\_config (R '/etc/libvirt/libvirtd.conf')

This string defines the location of the libvirtd configuration file.

#### network

This sections contains the networking parameters.

- listen\_tls: 0 or 1, enabled by default
- listen\_tcp: 0 or 1, disabled by default
- tls\_port: port number (16514) or service name
- tcp\_port: port number (16509) or service name
- listen\_addr (type\_hostname): IPv4/v6 address or hostname
- mdns\_adv: 0 or 1, enabled by default
- mdns\_name: default string is "Virtualization Host HOSTNAME"

#### socket

This section contains the configuration for unix sockets.

- unix\_sock\_group: restricted to root by default
- unix\_sock\_ro\_perms: octal string, default allows any user
- unix\_sock\_rw\_perms: octal string
- unix\_sock\_dir: directory of created sockets

#### authn

This section contains the authentication parameters.

- auth\_unix\_ro: 'none|sasl|polkit', default anyone
- auth\_unix\_rw: 'none|sasl|polkit', default polkit
- auth\_tcp' ? 'none|sasl', should be 'sasl' for production
- auth\_tls' ? 'none|sasl'

#### tls

This section contains the parameters for TLS. 

- key\_file: full path to key file
- cert\_file: full path to certificate file
- ca\_file: full path to certificate authority certificate
- crl\_file: fall path to CRL

#### authz

This section contains the authorization parameters. 

- tls\_no\_verify\_certificate: 0 or 1, defaults to verification
- tls\_allowed\_dn\_list: list of allowed DNs
- sasl\_allowed\_username\_list: list of allowed usernames

#### processing

This section contains the parameters used to control the processing. 

- max\_clients: maximum number of clients
- min\_workers: minimum number of workers
- max\_workers: maximum number of workers
- max\_requests: maximum number of requests
- max\_client\_requests: maximum number of client requests

#### logging

This section contains the parameters used to control the logging.

- log\_level: 4=errors,3=warnings,2=info,1=debug,0=none
- log\_filters: list of filters, see man for format
- log\_outputs: list of outputs, see man for format
