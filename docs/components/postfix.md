### NAME

ncm-postfix: Postfix server configuration

### DESCRIPTION

postfix

### RESOURCES

#### `/software/components/postfix`

The configuration information for the component. This structure
contains three fields:

- `main`

    An nlist with all the possible configuration values for
    `/etc/postfix/main.cf`. See [main(5)](http://man.he.net/man5/main) for more details.

- `master`

    A list with all entries for `/etc/postfix/master.cf`. See
    [master(5)](http://man.he.net/man5/master) for all the details. For each line, we have to provide:

    - `name` : string

        Name of the entry (first field in the line).

    - `type` :  string

        Type of service/socket for this entry.

    - `private` : boolean

        Defaults to true.

    - `unprivileged` : boolean

        Defaults to true

    - `chroot` : boolean

        Defaults to true

    - `maxproc` : long

        Maximum number of processes that may be instantiated following this
        line Defaults to 100.

    - `wakeup` : long
    - `command`

- `databases`

    An optional structure describing additional Postfix databases (lookup
    tables in Postfix terminology). See
    [http://www.postfix.org/DATABASE\_README.html](http://www.postfix.org/DATABASE_README.html) for more information.

    Each subtree is associated with a class of lookup tables. Each class
    of lookup tables is an nlist, in which the keys are the file names
    (relative to `/etc/postfix`) that configure the access to such a database.

    Currently, only LDAP lookups can be described, see
    [http://www.postfix.org/LDAP\_README.html](http://www.postfix.org/LDAP_README.html)

### EXAMPLES

#### Minimal configuration

An empty nlist is valid for `main.cf`:

    "/software/components/postfix/main" = nlist();

#### Storing aliases in LDAP

Declaring an alias database stored in an LDAP server can be achieved as follows:

    "/software/components/postfix/main/alias_maps" = append(
        nlist(
           "type", "ldap",
           "name", "/etc/postfix/ldap-aliases.cf"));

And we can instruct Postfix to access this database:

    prefix "/software/components/postfix/databases/ldap/ldap-aliases.cf";

    "server_host" = "foo.bar.com";
    "search_base" = "OU=foo,CN=bar";
    "query_filter" = "(an-ldap-filter)";
    "result_format" = "%s";
