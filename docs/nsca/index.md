---
layout: documentation
title: nsca
category: documentation
subcategory: components
menu: 'components.md'
---
### DESCRIPTION

The _nsca_ component manages the NSCA daemon and the NSCA client configuration.
The NSCA client (sender) is used to submit check results that are obtained on a node to the Nagios server.
In Nagios terms, they are known as passive check results (i.e. not initated by Nagios).

### COMPONENT STRUCTURE

This component can be used to configure an NSCA daemon and/or NSCA client. 
The daemon is only configured if its configuration exists under `/software/components/nsca/daemon`,
the client part is configured if the configuration under `/software/components/nsca/send` is defined.

#### NSCA DAEMON

All fields are mandatory, unless it is explicitly stated:

- `/software/components/nsca/daemon/pid`\_file : string

    The name of the file in which the NSCA daemon should write its process ID
    number.
    Defaults to "/var/run/nsca.pid".

- `/software/components/nsca/daemon/server`\_port : long

    Port number the daemon should wait for connections on.

- `/software/components/nsca/daemon/server`\_address : string

    Address that NSCA has to bind to in case there is more as one interface.
    This field is optional.

- `/software/components/nsca/daemon/user` : string

    This determines the effective user that the NSCA daemon should run as.
    Defaults to "nagios".

- `/software/components/nsca/daemon/group` : string

    This determines the effective group that the NSCA daemon should run as.
    Defaults to "nagios".

- `/software/components/nsca/daemon/chroot` : string

    This determines a directory into which the nsca daemon
    will perform a chroot(2) operation before dropping its privileges.
    This field is optional.

- `/software/components/nsca/daemon/debug` : boolean

    This option determines whether or not debugging
    messages are logged to the syslog facility.
    Defaults to false.

- `/software/components/nsca/daemon/command`\_file : string

    This is the location of the Nagios command file that the daemon
    should write all service check results that it receives.
    Defaults to "/var/log/nagios/rw/nagios.cmd".

- `/software/components/nsca/daemoni/alt`\_dump\_file : string

    This is used to specify an alternate file the daemon should
    write service check results to in the event the command file
    does not exist.
    Defaults to "/var/log/nagios/rw/nsca.dump".

- `/software/components/nsca/daemon/aggregate`\_writes : boolean

    This option determines whether or not the nsca daemon will
    aggregate writes to the external command file for client
    connections that contain multiple check results.
    Defaults to false.

- `/software/components/nsca/daemon/append`\_to\_file : boolean

    This option determines whether or not the nsca daemon will
    will open the external command file for writing or appending.
    Defaults to false.

- `/software/components/nsca/daemon/max`\_packet\_age : long

    This option is used by the nsca daemon to determine when client
    data is too old to be valid.
    Defaults to 30.

- `/software/components/nsca/daemon/password` : string

    This is the password/passphrase that should be used to decrypt the
    incoming packets.

- `/software/components/nsca/daemon/decryption`\_method : boolean

    This option determines the method by which the nsca daemon will
    decrypt the packets it receives from the clients.
    Defaults to 1.

#### NSCA CLIENT

- `/software/components/nsca/send/password` : string

    This is the password/passphrase that should be used to encrypt the
    outgoing packets.

- `/software/components/nsca/send/encryption`\_method : long

    This option determines the method by which the send\_nsca client will
    encrypt the packets it sends to the nsca daemon.
    Defaults to 1.

### SEE ALSO

http://nagios.sourceforge.net/docs/1\_0/addons.html\#nsca
