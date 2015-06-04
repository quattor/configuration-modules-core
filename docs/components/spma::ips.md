### NAME

NCM::Component::spma::ips - NCM SPMA configuration component for IPS

### SYNOPSIS

**Configure ()**

### DESCRIPTION

Invoked by **NCM::Component::spma** via '**ncm-ncd -configure ncm-spma**' when
**/software/components/spma/packager** is **ips**.  Processes requests for
IPS packages to be added to a new Solaris boot environment and generates a
command file that may be executed by **spma-run**.

This module is intended for package management with Quattor on Solaris 11
or later.

### RESOURCES

- **/software/catalogues** ? nlist {}

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

- **/software/requests** ? nlist ()

    A list of additional packages to install.  The format is:

    {_package\_name_}\[/{_version_}\]

    For example:

        '/software/requests/{ms/afs/client}' = nlist();
        '/software/requests/{idr537}/{2}' = '';

    The version number is optional and should generally be omitted.  It is
    intended that the version number of packages that can be requested individually
    are defined by a catalogue (e.g. constrained by an incorporate dependency).

- **/software/uninstall** ? nlist ()

    A list of packages to uninstall.  Packages in this list will not be installed,
    and will be passed to the **pkg install** command via the **--reject** option.
    The format is the same as with **/software/requests**.

- **/software/components/spma/packager** ? string

    Must contain '**ips**' to use this module.

- **/software/components/spma/run** ? string

    Set to **yes** to allow this module to launch **spma-run --execute** to make
    immediate changes to the new boot environment.  If set to **no** or omitted,
    this module prepares and validates the changes only, but does not perform
    any updates, it will be the responsibility of an external process to launch
    **spma-run --execute** in this case.

- **/software/components/spma/userpkgs** ? string

    Set to **yes** to allow user-installed packages.  If set to **no** or omitted,
    then SPMA will find all leaf packages that have not been requested and
    uninstall them via **--reject** arguments to **pkg install**.

- **/software/components/spma/pkgpaths** : string \[\]

    Contains a list of resource paths where catalogues and individual package
    requests are located.  Should be set to:

        list("/software/catalogues", "/software/requests");

- **/software/components/spma/uninstpaths** : string \[\]

    Contains a list of resource paths where packages to uninstall are located.
    Should be set to:

        list("/software/uninstall");

- **/software/components/spma/cmdfile** : string

    Where to save commands for the **spma-run** script.  Default location
    is **/var/tmp/spma-commands**.

- **/software/components/spma/flagfile** ? string

    File to touch if **/software/components/spma/run** is set to **no** and this
    module has determined that there is work to do, i.e. packages to install or
    to uninstall.  If the file exists after this module has completed, then
    **spma-run --execute** can be run to create a new BE and make package changes
    in that BE.

- **/software/components/spma/ips/bename** ? string

    Name of boot environment that **spma-run** will use when making any
    changes to packages.  If a BE by that name already exists, then a
    unique number will be appended to the name.  Package changes will
    be effected via '**pkg install --be-name** _bename_'.

    If this resource is missing then '**pkg install --require-new-be**' will be used
    instead, leaving Solaris to decide on the name of the new BE.

- **/software/components/spma/ips/rejectidr** : boolean

    Add a **--reject** option to the **pkg install** command for every Solaris IDR
    installed that has not been explicitly requested.

    Default is **true**.

- **/software/components/spma/ips/freeze** : boolean

    Ignore frozen packages.  This will prevent SPMA from updating or uninstalling
    frozen packages.

    Default is **true**.

### NOTES

This module does not support making changes in the currently active boot
environment.  The intention is that it is executed when a host is rebooted
via a call to '**ncm-ncd -configure spma**' and then '**spma-run --execute**'
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

**ncm-ncd**(1), **panc**(5), **pkg**(5), **spma-run --man**, **pkgtree -h**.
