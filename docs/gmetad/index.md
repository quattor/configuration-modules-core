---
layout: documentation
title: gmetad
category: documentation
subcategory: components
menu: 'components.md'
---
### DESCRIPTION

The _gmetad_ component manages Ganglia's gmetad daemon.
This daemon collects performance information from various nodes and stores it in a RRD database.

#### GMETAD

The configuration of gmetad is stored in the file `/etc/gmetad.conf`.

The schema for this component are very similar to the options in the configuration file.
More detailed information about the options can be found on the website (__SEE ALSO__).

- `/software/components/gmetad/data`\_source/\[srcindex\]/name : string

    Name of the data source.

- `/software/components/gmetad/data`\_source/\[srcindex\]/polling\_interval : long(1..)

    Optional polling interval for the data source, in seconds.

- `/software/components/gmetad/data`\_source/\[srcindex\]/host/\[hostindex\]/address : type\_hostname

    Host name or IP address per machine serving the data source.

- `/software/components/gmetad/data`\_source/\[srcindex\]/host/\[hostindex\]/port : type\_port

    Optional port for per machine serving the data source.

- `/software/components/gmetad/debug`\_level : long(0..)

    Optional level of debug output for the daemon.

- `/software/components/gmetad/scalability` : string

    Optional flag to enable or disable scalability mode. 
    Valid values are `on` and `off`.

- `/software/components/gmetad/file` : string

    Mandatory field specifying the location of the the configuration file.
    For Ganglia 3.0, this should be `/etc/gmetad.conf`
    and for Ganglia 3.1, it should be `/etc/ganglia/gmetad.conf`.

- `/software/components/gmetad/gridname` : string

    Optional name of the grid.

- `/software/components/gmetad/authority` : type\_absoluteURI

    Optional authority URL for this grid.

- `/software/components/gmetad/trusted`\_hosts : type\_hostname\[\]

    Optional list of trusted hosts.

- `/software/components/gmetad/all`\_trusted : string

    Optional field to enable trust of all hosts.
    Valid values are `on` and `off`.

- `/software/components/gmetad/setuid` : string

    Optional flag to control setuid mode of the daemon.
    Valid values are `on` and `off`.

- `/software/components/gmetad/setuid`\_username : string

    Optional name of the user account running the daemon.

- `/software/components/gmetad/xml`\_port : type\_port

    Optional port gmetad will answer requests for XML.

- `/software/components/gmetad/interactive`\_port : type\_port

    Optional port gmetad will answer queries for XML.

- `/software/components/gmetad/server`\_threads : long(1..)

    Optional number of threads answering XML requests.

- `/software/components/gmetad/rrd`\_rootdir : string

    Optional directory where gmetad stores its RRD databases.

### SEE ALSO

http://ganglia.wiki.sourceforge.net/
