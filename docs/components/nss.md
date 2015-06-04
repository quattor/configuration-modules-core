### NAME

NCM::nss - NCM nsswitch component

### SYNOPSIS

- Configure()

    Generates `/etc/nsswitch.conf` Returns error in case of failure. If the
    nsswitch.conf file is modified and nscd is running, then nscd will be
    restarted.

- Unconfigure()

    not available.

### RESOURCES

- `/software/components/nss/active` : boolean

    activates/deactivates the component.

- `/software/components/nss/databases` : nlist

    A list of database names (e.g. "passwd", "hosts"). Each
    name should be associated with a list of strings.

- `/software/components/nss/build` : nlist

    A list of database types (e.g. "file", "db"). If any
    nss sources are set to use one of these database types
    then the "build" item will be checked to see if there
    is a script that should be run in order to build the
    database. If so, this script will be run before changing
    nsswitch.conf. The script will be run once for each
    entry in nsswitch.conf that uses that data source.
    The value of each key should be an nlist
    with the following possible keys

    - script

        the command line to run to generate once for each database.
        Any token of the form "<DB>" will be substituted with the
        name of the database being built.

    - active

        if false, then the build script will not be run.

    - depends

        A database name can be provided. If specified, then
        that database will be built before processing any
        databases of this type.

### EXAMPLES

    "/software/components/nss" = nlist(
       "build", nlist(
           "db", nlist("script", "make -f `/usr/local/lib/dbfiles.mk` <DB>")
       ),

       "database", nlist(
           "hosts",    list("files", "nis", "dns"),
           "passwd",   list("files", "db"),
           "networks", list("nis", "files", "[NOTFOUND=return]"),
       )
     );

### FILES MODIFIED

The component modifies the following files:

- `/etc/nsswitch.conf`

### DEPENDENCIES

#### Components to be run before:

none.

#### Components to be run after:

none.

### BUGS

see code.

S

### SEE ALSO

ncm-ncd(1), nsswitch.conf(5)
