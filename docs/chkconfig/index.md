---
layout: documentation
title: chkconfig
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

NCM::chkconfig - NCM chkconfig component

### SYNOPSIS

- Configure()

    Updates runlevel information for system services by using __chkconfig__ that are
    defined in `/software/components/chkconfig`/. 

    Also starts/stops those services that have option `startstop` set to true in 
    and have one of the following options specified: 
    `add` or `del` option is true, `on` or `off` option is specified either 
    without specific runlevels, or with runlevel value that contains the current runlevel. 

    The optional _default_ key decides what will happen with services that are not explicitly
    configured. Default is to ignore them, but a vakue of _off_ instead disables anything
    not mentioned in the profile.

- Unconfigure()

    Not available.

### RESOURCES

- `/software/components/chkconfig/active : boolean`

    activates/deactivates the component.

- `/software/components/chkconfig/default : string ("off", "ignore")`

    says what happens if no explicit configuration is found for the
    service. Certain services (like `network, messagebus, haldaemon,
    sshd`) are protected from being turned off via the default setting,
    but please do not rely on this.

- `/software/components/chkconfig/service/<service>/off : string ("[0-7]*")`
- `/software/components/chkconfig/service/<service>/on : string ("[0-7]*")`

    Sets the service <service> on/off on specified run levels. The run
    levels are specified as string of numbers, the same way as with
    `chkconfig`\-command. If the string is empty, system default is taken
    (see `man chkconfig(8)` for exact details).

- `/software/components/chkconfig/service/<service>/name : string`

    If set, the value is used as the name of the service instead of using the 
    <service> path as a name. 

- `/software/components/chkconfig/service/<service>/reset : string ("[0-7]*")`

    Resets the service on defined run levels. Reset with no run levels specified 
    affects every run level. 

- `/software/components/chkconfig/service/<service>/add : boolean`

    If the value is true, adds service for management by chkconfig (if not
    already the case), otherwise the option is ignored. Please note that
    some services do not turn themselves on, and so in addition need an
    explicit _on_ for the appropriate runlevels.

    If service has value 'add', and is already known to chkconfig, 'reset'
    will be run. This will restore service runlevel to its default values
    and protect from any manual changes of runlevels by `/sbin/chkconfig.`

- `/software/components/chkconfig/service/<service>/del : boolean`

    If the value is true, removes service from management by chkconfig, otherwise
    the option is ignored. 

- `/software/components/chkconfig/service/<service>/startstop : boolean`

    If true, the service is also started/stopped when the service is
    added, removed or turned off/on. The component tries to check whether
    a certain service is already running or stopped and will not redo the
    action, but this relies on the service's init script correctly
    reporting current state.

### EXAMPLES

The following example will start named on system default runlevels:

    include { 'components/chkconfig/config' };
    "/software/components/chkconfig/service/named/add" = true;
    "/software/components/chkconfig/service/named/on" = "";
    "/software/components/chkconfig/service/named/startstop" = true;

The shorter way of writing this (assuming named is known to chkconfig):

    include { 'components/chkconfig/config' };
    "/software/components/chkconfig/service/named" =
         nlist("on","","startstop",true);

Disable and stop xinetd:

    "/software/components/chkconfig/service/xinetd" = nlist("off", "", "startstop", true); 

### DEPENDENCIES

None.

### BUGS

- [https://savannah.cern.ch/bugs/?45924](https://savannah.cern.ch/bugs/?45924)

    The component should better integrate with the standard boot sequence
    (not start services that will get started anyway later).

- __reset__ behaviour should check against current config?
- __startstop__ logic depends on init script, will mindlessly start some services despite them running already

Teemu Sidoroff <Teemu.S>

### SEE ALSO

ncm-ncd(1), chkconfig(8), http://cern.ch/quattor
