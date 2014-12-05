### DESCRIPTION

The _gmond_ component manages Ganglia's gmond daemon.
This daemon collects information at a node and uses multicast to distribute it
over the network.

#### GMOND

The organization of the schema is very similar to the layout of the resulting configuration file.
Please read Ganglia's documentation on the configuration of gmond for details.

- `/software/components/gmond/file` : string

    The location of the configuration file. The correct value differs between 
    Ganglia 3.0 (/etc/gmond.conf) and Ganglia 3.1 (/etc/ganglia/gmond.conf).
    There is no default value.

- `/software/components/gmond/cluster`

    Cluster configuration with attributes name, owner, latlong and url.

- `/software/components/gmond/host`

    Host configuration with attribute location.

- `/software/components/gmond/globals`

    Configuration of gmond, with attributes daemonize, setuid, user, debug\_level,
    mute, deaf, host\_dmax, cleanup\_threshold, gexec, send\_metadata\_interval and module\_dir.

- `/software/components/gmond/udp`\_send\_channel

    List of UDP channels to send information to. 
    Per channel the attributes mcast\_join, mcast\_if, host, port and ttl may be configured.

- `/software/components/gmond/udp`\_recv\_channel

    List of UDP channels to receive information from. 
    Per channel the attributes mcast\_join, mcast\_if, bind, port, family and an acl may be configured.

- `/software/components/gmond/tcp`\_accept\_channel

    List of TCP channels from which information is accepted.
    Per channel the attributes bind, port, family, timeout and an acl may be configured.

- `/software/components/gmond/collection`\_group

    List of collection groups.
    Per collection group the attributes collect\_once, collect\_every, time\_threshold and a list of
    metric descriptions can be specified.
    For each metric, the attributes name, title and value\_threshold can be given.

- `/software/components/gmond/module`

    List of modules.
    Per module the attributes name, language, path, params and param can be specified.

- `/software/components/gmond/include`

    Optional list of additional files to include.

### SEE ALSO

See 
http://ganglia.wiki.sourceforge.net/
for documentation on Ganglia and gmond.
