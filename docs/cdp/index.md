---
layout: documentation
title: cdp
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

The _cdp_ component manages the configuration file
`/etc/cdp`-listend.conf.

### DESCRIPTION

The _cdp_ component manages the configuration file for the
cdp-listend daemon.

### RESOURCES

#### configfile (/etc/cdp-listend.conf)

The location of the configuration file.  Normally this should not be
changed. 

#### port

The port used by the daemon.  

#### nch

The binary to execute when receiving a CDB update packet.

#### nch\_smear

The range of time delay for executing the nch executable.  The
execution will be delayed by \[0, nch\_smear\] seconds.

#### fetch

The binary to execute when receiving a CCM update packet.

#### fetch\_smear

The range of time delay for executing the fetch executable.  The
execution will be delayed by \[0, fetch\_smear\] seconds.
