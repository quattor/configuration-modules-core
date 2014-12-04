---
layout: documentation
title: spma / ips
category: documentation
subcategory: components
menu: 'components.md'
---
### NAME

NCM::Component::spma::ips - NCM SPMA configuration component for IPS

### SYNOPSIS

__Configure ()__

### DESCRIPTION

Invoked by __NCM::Component::spma__ via '__ncm-ncd -configure ncm-spma__' when
__/software/components/spma/packager__ is __ips__.  Processes requests for
IPS packages to be added to a new Solaris boot environment and generates a
command file that may be executed by __spma-run__.

This module is intended for package management with Quattor on Solaris 11
or later.

### RESOURCES

- __/software/catalogues__ ? nlist {}

    A list of catalogues (package groups) to install.  The format is:

    {_package\_name_}/{_version_}

    For example:

        prefix '/software/catalogues';
        '{pkg://solaris/entire}/{0.5.11,5.11-0.175.1.10.0.5.0}' = '';

    The intention is that a host's software inventory is predominantly defined
    by a small number of software catalogues that pull in almost all of the
    packages required for the build.

    Catalogues must be versioned and a host is progressed from one version
    of a build to another by shifting the catalogue version numbers.

- __/software/requests__ ? nlist ()

    A list of additional packages to install.  The format is:

    {_package\_name_}\[/{_version_}\]

    For example:

        '/software/requests/{ms/afs/client}' = nlist();
        '/software/requests/{idr537}/{2}' = '';

    The version number is optional and should generally be omitted.  It is
    intended that the version number of packages that can be requested individually
    are defined by a catalogue (e.g. constrained by an incorporate dependency).

- __/software/uninstall__ ? nlist ()

    A list of packages to uninstall.  Packages in this list will not be installed,
    and will be passed to the __pkg install__ command via the __\--reject__ option.
    The format is the same as with __/software/requests__.

- __/software/components/spma/packager__ ? string

    Must contain '__ips__' to use this module.

- __/software/components/spma/run__ ? string

    Set to __yes__ to allow this module to launch __spma-run --execute__ to make
    immediate changes to the new boot environment.  If set to __no__ or omitted,
    this module prepares and validates the changes only, but does not perform
    any updates, it will be the responsibility of an external process to launch
    __spma-run --execute__ in this case.

- __/software/components/spma/userpkgs__ ? string

    Set to __yes__ to allow user-installed packages.  If set to __no__ or omitted,
    then SPMA will find all leaf packages that have not been requested and
    uninstall them via __\--reject__ arguments to __pkg install__.

- __/software/components/spma/pkgpaths__ : string \[\]

    Contains a list of resource paths where catalogues and individual package
    requests are located.  Should be set to:

        list("/software/catalogues", "/software/requests");

- __/software/components/spma/uninstpaths__ : string \[\]

    Contains a list of resource paths where packages to uninstall are located.
    Should be set to:

        list("/software/uninstall");

- __/software/components/spma/cmdfile__ : string

    Where to save commands for the __spma-run__ script.  Default location
    is __/var/tmp/spma-commands__.

- __/software/components/spma/flagfile__ ? string

    File to touch if __/software/components/spma/run__ is set to __no__ and this
    module has determined that there is work to do, i.e. packages to install or
    to uninstall.  If the file exists after this module has completed, then
    __spma-run --execute__ can be run to create a new BE and make package changes
    in that BE.

- __/software/components/spma/ips/bename__ ? string

    Name of boot environment that __spma-run__ will use when making any
    changes to packages.  If a BE by that name already exists, then a
    unique number will be appended to the name.  Package changes will
    be effected via '__pkg install --be-name__ _bename_'.

    If this resource is missing then '__pkg install --require-new-be__' will be used
    instead, leaving Solaris to decide on the name of the new BE.

- __/software/components/spma/ips/rejectidr__ : boolean

    Add a __\--reject__ option to the __pkg install__ command for every Solaris IDR
    installed that has not been explicitly requested.

    Default is __true__.

- __/software/components/spma/ips/freeze__ : boolean

    Ignore frozen packages.  This will prevent SPMA from updating or uninstalling
    frozen packages.

    Default is __true__.

### NOTES

This module does not support making changes in the currently active boot
environment.  The intention is that it is executed when a host is rebooted
via a call to '__ncm-ncd -configure spma__' and then '__spma-run --execute__'
called immediately afterwards.  The system will then reboot into the
newly created boot environment if any changes were made.

IPS publisher configuration is currently not supported by this module.

### EXAMPLE CONFIGURATION

The following PAN code snippet demonstrates how to prepare SPMA for
Solaris:

    #
    ### Configure SPMA appropriately for Solaris
    #
    prefix "/software/components/spma";
    "packager" = "ips";
    "pkgpaths" = list("/software/catalogues", "/software/requests");
    "uninstpaths" = list("/software/uninstall");
    "register_change" = list("/software/catalogues",
                             "/software/requests",
                             "/software/uninstall");
    "flagfile" = "/var/tmp/spma-run-flag"

Original author: German Cancio <German.C>

Author of the IPS-based package manager: Mark R. Bannister.

### SEE ALSO

__ncm-ncd__(1), __panc__(5), __pkg__(5), __spma-run --man__, __pkgtree -h__.
