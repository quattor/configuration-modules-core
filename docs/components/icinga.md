### DESCRIPTION

The _icinga_ component manages the configuration for the Icinga
monitoring system.

At the time of this writing, escalations and dependencies are the only
Icinga settings this component doesn't understand.

### BASIC COMPONENT STRUCTURE

Icinga configuration is very complicated. Before reading this, please
check the Icinga documentation.  All the fields on this component are
named just like the tags for the appropriate Icinga object.

- `/software/components/icinga/general`

    Global settings for Icinga. These settings will be written in
    `/etc/icinga/icinga.cfg` .

- `/software/components/icinga/cgi`

    Configuration of the Icinga web interface.
    This path is optional. If it exists, the settings will be
    written in `/etc/icinga/cgi.cfg`.

- `/software/components/icinga/hosts`

    Host definitions, indexed by host name. There is no host\_name option,
    as it is taken from the index. Also, the host\_address field is
    optional. If it's not provided, gethostbyname is used to decide the
    host's IP address.

    These settings are written in `/etc/icinga/objects/hosts.cfg` .

- `/software/components/icinga/hostgroups`

    Hostgroup definitions, indexed by hostgroup name. These settings are
    written in `/etc/icinga/objects/hostgroups.cfg` .

- `/software/components/icinga/hostdependencies`

    Host dependency defintions, indexed by **depended** host name (this is,
    where the arrow ends in Icinga documentation).

    These settings are written in `/etc/icinga/objects/hostdependencies.cfg`

- `/software/components/icinga/services`

    nlist of lists of service definitions. The keys are the service
    descriptions, escaped. The value is a list of service definitions that
    share the same definition but have different parameters (e.g,
    commands).

    Please check that you don't list the same host on two entries of the
    same service, as the validation code won't detect this and will cause
    Icinga to fail.

    These settings are written in `/etc/icinga/objects/services.cfg` .

- `/software/components/icinga/servicegroups`

    List of service groups. It is written in `/etc/icinga/objects/servicegroups.cfg`

- `/software/components/icinga/servicedependencies`

    List of service dependencies. It is written in
    `/etc/icinga/objects/servicedependencies.cfg`

- `/software/components/icinga/contacts`

    Contact definition, indexed by contact name.

    These settings are written in `/etc/icinga/objects/contacts.cfg` .

- `/software/components/icinga/contactgroups`

    Contact group definition, indexed by contact group name. These
    settings are written in `/etc/icinga/objects/contactgroups.cfg` .

- `/software/components/icinga/commands`

    Command lines, indexed by Icinga command name. These settings are
    stored in `/etc/icinga/objects/commands.cfg` .

- `/software/components/icinga/macros`

    Icinga $USERx$ macros, indexed by macro name. The macro name must not
    be surrounded by '$'. These settings are stored in
    `/etc/icinga/resources.cfg` .

- `/software/components/icinga/timeperiods`

    Icinga time period definition, indexed by time period name. Time
    periods are stored in `/etc/icinga/objects/timeperiods.cfg` .

- `/software/components/icinga/serviceextinfo`

    Definition for extended service information. These settings are saved
    in `/etc/icinga/objects/serviceextinfo.cfg` .

- `/software/components/icinga/external`\_files

    Other already existing files to be included in the configuration of
    Icinga. Please note that the component can't validate these, so if you
    include a broken file, you'll break your Icinga server!

- `/software/components/icinga/external`\_dirs

    Other already existing dirs to be included in the configuration of
    Icinga. Please note that the component can't validate these, so if you
    include a broken file, you'll break your Icinga server!

### NOTES ON THE USE OF THIS COMPONENT

#### Command usage

When a service or a host references a command, it separates its arguments with '!', e.g:

    check_command check_load!5,4,3!6,5,4

where `check_load` is an existing Icinga command. On this component,
that should be specified as

    "check_command" = list ("check_load", "5,4,3", "6,5,4");

Check commands and event handlers are defined as such lists of
strings, where the first element must be an existing command name. For
the above example to be valid,
`/software/components/icinga/commands/check_load` must exist.

#### The `use` tag

The `use` tag is not allowed by this component. It makes validation
almost impossible, and any attempt to implement an incomplete
validation would make the compilation awfully slow.

However, Pan offers the same functionality as the `use` tag, without
giving up with validation. You may want to use `value`, `include`
and `create` to simulate Icinga inheritance.

The only downside of this approach is the growth of the LLD profile.

### FILES

The following files are written by this component:

- `/etc/icinga/icinga.cfg`
- `/etc/icinga/cgi.cfg`
- `/etc/icinga/objects/contacts.cfg`
- `/etc/icinga/objects/contactgroups.cfg`
- `/etc/icinga/objects/hosts.cfg`
- `/etc/icinga/objects/hostgroups.cfg`
- `/etc/icinga/objects/hostdependencies.cfg`
- `/etc/icinga/objects/services.cfg`
- `/etc/icinga/objects/servicegroups.cfg`
- `/etc/icinga/objects/servicedependencies.cfg`
- `/etc/icinga/objects/serviceextinfo.cfg`
- `/etc/icinga/objects/timeperiods.cfg`
- `/etc/icinga/objects/commands.cfg`
- `/etc/icinga/resources.cfg`

If they exist, they will be truncated, the owner and group set to
Icinga and the permissions will be set to 0660.

Note that `config_file` and `resource_file` directives are not
valid. To keep consistency, everything must be set according to this
layout.

### SEE ALSO

http://www.icinga.org/docs/
