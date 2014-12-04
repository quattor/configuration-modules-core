---
layout: documentation
title: ntpd
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

NCM::ntpd - NCM ntpd configuration component

### SYNOPSIS

- Configure()

    This component configures the ntpd (Network Time Protocol) server to
    start at boot time, and configures the time servers from CDB. If
    anything changed in the configuration, it will restart ntpd.

- Unconfigure()
Does nothing.

### RESOURCES

- `/software/components/ntpd/active` : boolean

    activates/deactivates the component.

- `/software/components/ntpd/servers`/ : list of time servers
- `/software/components/ntpd/serverlist`/ : list of { server=hostname, options=nlist() }

- server : string (required)

    Can be ip address or qualified DNS hostname

- options : nlist (optional)

    Refer to man ntp.conf for details for command options for server

    Default : `/software/components/ntpd/defaultoptions` or None if not specified
    and defaultoptions

    - autokey:   boolean (optional)
    - burst:     boolean  (optional)
    - iburst:    boolean  (optional)
    - key:       long  (optional)
    - minpoll:   long  (optional)
    - maxpoll:   long  (optional)
    - noselect:  boolean  (optional)
    - preempt:   boolean  (optional)
    - prefer:    boolean  (optional)
    - true:      boolean  (optional)
    - version:   long  (optional)

- `/software/components/ntpd/clientnetworks` : list of { net=, mask= }

    optional: clients that can use this server to synchronize. Default allows
    connections from localhost only.

- `/software/components/ntpd/defaultoptions` : nlist (optional)

    Specifies default command options for each timeserver defined in servers
    or serverlist.
    Refer to man ntp.conf for details.

    Default : None

    - autokey:   boolean (optional)
    - burst:     boolean  (optional)
    - iburst:    boolean  (optional)
    - key:       long  (optional)
    - minpoll:   long  (optional)
    - maxpoll:   long  (optional)
    - noselect:  boolean  (optional)
    - preempt:   boolean  (optional)
    - prefer:    boolean  (optional)
    - true:      boolean  (optional)
    - version:   long  (optional)

- `/software/components/ntpd/restrictdefault` : nlist (optional)

    Refer to man ntp\_acc for more information or access control commands.

    Default : restrict default ignore

    - mask:        ip address or hostname (optional)

        Address can be a address of a host or network and can be a valid host DNS name.
        =item ignore:      boolean (Default to True)

    - kod:         boolean (optional)
    - limited:     boolean (optional)
    - lowpriotrap: boolean (optional)
    - nomodify:    boolean (optional)
    - noquery:     boolean (optional)
    - nopeer:      boolean (optional)
    - noserve:     boolean (optional)
    - notrap:      boolean (optional)
    - notrust:     boolean (optional)
    - ntpport:     boolean (optional)
    - version:     long(1..4) (optional)

        Deny packets that do not match the current NTP version

- `/software/components/ntpd/authenticate` : boolean (optional)

    Adds string 'authenticate yes' to ntp.conf

    Default : None

- `/software/components/ntpd/broadcastdelay` : double (optional)

    Double value in seconds to set network delay between local and remote servers.

    Refer to man ntp\_misc for more details.

    Default : None

- `/software/components/ntpd/keyfile` : string (optional)

    Specifies the complete path and location of the MD5 key file containing the
    keys and key identifiers used by ntpd, ntpq and ntpdc when operating with
    symmetric key cryptography.
    Refer to man ntp\_auth for more details.

    Default : None

- `/software/components/ntpd/trustedkey` : list of integers (optional)

    Requires keyfile set.
    Refer to man ntp\_auth for more details.

    Default : None

- `/software/components/ntpd/requestkey` : long (optional)

    Specifies the key identifier to use with the ntpdc utility program.
    Requires keyfile set.
    Refer to man ntp\_auth for more details.

    Default : None

- `/software/components/ntpd/controlkey` : long (optional)

    Specifies the key identifier to use with the ntpq utility.
    Requires keyfile set.
    Refer to man ntp\_auth for more details.

    Default : None

- `/software/components/ntpd/driftfile` : string (optional)

    This command specifies the complete path and name of the file used to record
    the frequency of the local clock oscillator.

    Default : None

- `/software/components/ntpd/includefile` : string (optional)

    This command allows additional configuration commands to be included
    from a separate file.

    Default : None

- `/software/components/ntpd/logfile` : string (optional)

    Refer to man ntp\_misc for more details.

    Default : None

- `/software/components/ntpd/logconfig` : list of strings (optional)
Log configuration arguments must be defined in a list of strings.
Values for each argument must follow the defined in ntp\_misc manual.
Refer to man ntp\_misc for more details.

    examples:

    prefix "/software/components/ntpd";

    \#logconfig =syncstatus +sysevents
    "logconfig" = list("=syncstatus", "+sysevent");

    Default : None

- `/software/components/ntpd/statsdir` : string (optional)

    Refer to man ntp\_misc for more details.

    Default : None

- `/software/components/ntpd/statistics` : nlist (optional)

    Refer to man ntp\_misc for more details.

    Default : None

    example:
    prefix "/software/components/ntpd";

    "statistics" = nlist();
    "statistics/loopstats" = true;
    "statistics/peerstats" = true;

    - clockstats :  boolean (optional)
    - cryptostats : boolean (optional)
    - loopstats :   boolean (optional)
    - peerstats :   boolean (optional)
    - rawstats :    boolean (optional)
    - sysstats :    boolean (optional)

- `/software/components/ntpd/filegen` : list of nlist (optional)

    Refer to man ntp\_misc for more details.

    Default : None

    example:

    \#filegen loopstats file loopstats type day enable
    \#filegen peerstats file peerstats type day enable
    prefix "/software/components/ntpd";

    "filegen" = list();
    "filegen/0" = nlist();
    "filegen/0/name" = "loopstats";
    "filegen/0/file" = "loopstats";
    "filegen/0/type" = "day";
    "filegen/0/enableordisable" = "enable";
    "filegen/1" = nlist();
    "filegen/1/name" = "peerstats";
    "filegen/1/file" = "peerstats";
    "filegen/1/type" = "day";
    "filegen/1/enableordisable" = "enable";

    - name : string (optional)

        value can be set to 'clockstats|cryptostats|loopstats|peerstats|rawstats|sysstats'

    - file : string (optional)
    - type : string (optional)

        value can be 'none|pid|day|week|month|year|age'

    - linkornolink"    ? string (optional)

        value must be either 'link' or 'nolink'

    - enableordisable : string (optional)

        value must be either 'enable' or 'disable'

- `/software/components/ntpd/enable` : nlist (optional)

    Provides a way to enable various system options.
    Flags not mentioned are unaffected.
    Note that all of these flags can be controlled remotely using
    the ntpdc utility program
    Refer to man ntp\_misc for more details.

    Default : None

    - auth :      boolean (optional)
    - blient :    boolean (optional)
    - calibrate : boolean (optional)
    - kernel :    boolean (optional)
    - monitor :   boolean (optional)
    - ntp :       boolean (optional)
    - pps :       boolean (optional)
    - stats :     boolean (optional)

- `/software/components/ntpd/disable` : nlist (optional)

    Provides a way to enable various system options.
    Flags not mentioned are unaffected.
    Note that all of these flags can be controlled remotely using
    the ntpdc utility program
    Refer to man ntp\_misc for more details.

    Default : None

    - auth :       boolean (optional)
    - blient :     boolean (optional)
    - calibrate :  boolean (optional)
    - kernel :     boolean (optional)
    - monitor :    boolean (optional)
    - ntp :        boolean (optional)
    - pps :        boolean (optional)
    - stats :      boolean (optional)

- `/software/components/ntpd/tinker` : nlist (optional)

    Refer to man ntp\_misc for more details.

    Default : None

    - allan:      long (optional)
    - dispersion: long (optional)
    - freq:       long (optional)
    - huffpuff:   long (optional)
    - panic:      long (optional)
    - step:       long (optional)
    - stepout:    long (optional)

- `/software/components/ntpd/servicename` : string (optional)

    override the deamon name to restart service. some platforms such as solaris
    use a different service name to represent ntpd.

    Example:
    	\### solaris
    	"/software/components/ntpd/servicename" = "svc:/network/ntpd";

    	### linux
    	"/software/components/ntpd/servicename" = "ntpd";

    Default : "ntpd" (linux), "svc:/network/ntpd" (solaris)

- `/software/components/ntpd/includelocalhost` : boolean (optional)

    includes fudge options for localhost's clock

    Default : true

- `/software/components/ntpd/enablelocalhostdebug` : boolean (optional)

    Allows some debugging via ntpdc on localhost but with no modifications

    Default : true

### DEPENDENCIES

#### Components to be run before:

none.

#### Components to be run after:

none.

### BUGS

none known.

S

- Thorsten Kleinwort <Thorsten.Kleinwort@cern.ch>
- John Monteiro <John.M>

### SEE ALSO

ncm-ncd(1), ntpd(1)
