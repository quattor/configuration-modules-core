---
layout: documentation
title: nagios
category: documentation
subcategory: components
menu: 'components.md'
---
### DESCRIPTION

The _nagios_ component manages the configuration for the Nagios
monitoring system.

At the time of this writing, escalations and dependencies are the only
Nagios settings this component doesn't understand.

### BASIC COMPONENT STRUCTURE

Nagios configuration is very complicated. Before reading this, please
check the Nagios documentation.  All the fields on this component are
named just like the tags for the appropriate Nagios object.

- `/software/components/nagios/general`

    Global settings for Nagios. These settings will be written in
    `/etc/nagios/nagios.cfg` .

- `/software/components/nagios/cgi`

    Configuration of the Nagios web interface. 
    This path is optional. If it exists, the settings will be
    written in `/etc/nagios/cgi.cfg`. 

- `/software/components/nagios/hosts`

    Host definitions, indexed by host name. There is no host\_name option,
    as it is taken from the index. Also, the host\_address field is
    optional. If it's not provided, gethostbyname is used to decide the
    host's IP address.

    These settings are written in `/etc/nagios/hosts.cfg` .

- `/software/components/nagios/hostgroups`

    Hostgroup definitions, indexed by hostgroup name. These settings are
    written in `/etc/nagios/hostgroups.cfg` .

- `/software/components/nagios/hostdependencies`

    Host dependency defintions, indexed by __depended__ host name (this is,
    where the arrow ends in Nagios documentation).

    These settings are written in `/etc/nagios/hostdependencies.cfg`

- `/software/components/nagios/services`

    nlist of lists of service definitions. The keys are the service
    descriptions, escaped. The value is a list of service definitions that
    share the same definition but have different parameters (e.g,
    commands).

    Please check that you don't list the same host on two entries of the
    same service, as the validation code won't detect this and will cause
    Nagios to fail.

    These settings are written in `/etc/nagios/services.cfg` .

- `/software/components/nagios/servicegroups`

    List of service groups. It is written in `/etc/nagios/servicegroups.cfg`

- `/software/components/nagios/servicedependencies`

    List of service dependencies. It is written in
    `/etc/nagios/servicedependencies.cfg`

- `/software/components/nagios/contacts`

    Contact definition, indexed by contact name.

    These settings are written in `/etc/nagios/contacts.cfg` .

- `/software/components/nagios/contactgroups`

    Contact group definition, indexed by contact group name. These
    settings are written in `/etc/nagios/contactgroups.cfg` .

- `/software/components/nagios/commands`

    Command lines, indexed by Nagios command name. These settings are
    stored in `/etc/nagios/commands.cfg` .

- `/software/components/nagios/macros`

    Nagios $USERx$ macros, indexed by macro name. The macro name must not
    be surrounded by '$'. These settings are stored in
    `/etc/nagios/resources.cfg` .

- `/software/components/nagios/timeperiods`

    Nagios time period definition, indexed by time period name. Time
    periods are stored in `/etc/nagios/timeperiods.cfg` .

- `/software/components/nagios/serviceextinfo`

    Definition for extended service information. These settings are saved
    in `/etc/nagios/serviceextinfo.cfg` .

- `/software/components/nagios/external`\_files

    Other already existing files to be included in the configuration of
    Nagios. Please note that the component can't validate these, so if you
    include a broken file, you'll break your Nagios server!

- `/software/components/nagios/external`\_dirs

    Other already existing dirs to be included in the configuration of
    Nagios. Please note that the component can't validate these, so if you
    include a broken file, you'll break your Nagios server!

### NOTES ON THE USE OF THIS COMPONENT

#### Command usage

When a service or a host references a command, it separates its arguments with '!', e.g:

    check_command check_load!5,4,3!6,5,4

where `check_load` is an existing Nagios command. On this component,
that should be specified as

    "check_command" = list ("check_load", "5,4,3", "6,5,4");

Check commands and event handlers are defined as such lists of
strings, where the first element must be an existing command name. For
the above example to be valid,
`/software/components/nagios/commands/check_load` must exist.

#### The `use` tag

The `use` tag is not allowed by this component. It makes validation
almost impossible, and any attempt to implement an incomplete
validation would make the compilation awfully slow.

However, Pan offers the same functionality as the `use` tag, without
giving up with validation. You may want to use `value`, `include`
and `create` to simulate Nagios inheritance.

The only downside of this approach is the growth of the LLD profile.

### FILES

The following files are written by this component:

- `/etc/nagios/nagios.cfg`
- `/etc/nagios/cgi.cfg`
- `/etc/nagios/contacts.cfg`
- `/etc/nagios/contactgroups.cfg`
- `/etc/nagios/hosts.cfg`
- `/etc/nagios/hostgroups.cfg`
- `/etc/nagios/hostdependencies.cfg`
- `/etc/nagios/services.cfg`
- `/etc/nagios/servicegroups.cfg`
- `/etc/nagios/servicedependencies.cfg`
- `/etc/nagios/serviceextinfo.cfg`
- `/etc/nagios/timeperiods.cfg`
- `/etc/nagios/commands.cfg`
- `/etc/nagios/resources.cfg`

If they exist, they will be truncated, the owner and group set to
Nagios and the permissions will be set to 0660.

Note that `config_file` and `resource_file` directives are not
valid. To keep consistency, everything must be set according to this
layout.

### SEE ALSO

http://www.nagios.org/docs/
