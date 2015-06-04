### DESCRIPTION

The _sudo_ component manages the sudo configuracion, I.E: edits
`/etc/sudoers.` It doesn't provide as strict and nice syntax and
semantic correction as visudo(8) does, but it tries to warn on most
common users' mistakes.

### BASIC COMPONENT STRUCTURE

On top, it provides the following fields:

- `/software/components/sudo/general`\_options : optional

    It is a list of `structure_sudo_defaults` elements. It sets default
    behaviour either for users or hosts, or for the whole sudo
    application. This structure will be explained later.

- "/software/components/sudo/<user|run\_as|host|cmd>\_aliases :
optional

    Named lists of lists of strings containing the alias information.  The
    name of each named list must start with a letter, and contain only
    letters, numbers and underscores. All the letters must be
    capitals. I.E: the name must match `^[A-Z][A-Z0-9_]*$`

    They can be preceeded by an '!', indicating the alias must **not**
    match that name. The contents may be preceeded by an !, indicating
    that item must **not** be part of the alias.

    The contents of host aliases can be either host names, IP addresses or
    network specifications (IP/netmask).

    A valid example:

            "/software/components/sudo/user_aliases" = nlist ("FOO",
                    list ("bar", "%wheel", "!root"));

- `/software/components/sudo/privilege`\_lines : mandatory

    A list of structures of the type `structure_privilege_line`, each one
    specifying a way for a normal user to upgrade its privileges.

### GENERAL OPTIONS STRUCTURE

The `structure_sudo_default` defines the possible default behaviour
an user may find when running sudo. This settings are applied
globally, just to a host, just to an user, or just to a supplanted
user.

- `/software/components/sudo/general`\_options/\[n\]/user : optional

    The user the following settings apply to.

- `/software/components/sudo/general`\_options/\[n\]/host : optional

    The host the following settings apply to.

- `/software/components/sudo/general`\_options/\[n\]/run\_as : optional

    The supplanted user the following settings apply to.

- `/software/components/sudo/general`\_options/\[n\]/options : optional

    The named list of options that can be specified. Currently, only
    atomic options are supported.
    Boolean, integer and string values are handled correctly.

For a given setting, **at most** one of `user`, `host` or `run_as`
must be set. It is a compile error to set two or more of these.

For instance, this is valid:

        "/software/components/sudo/sudo/general_options" =
                list (
                      nlist ("user", "foo",
                             "options", nlist ("insults", true, "mailerpath", "/sbin/sendmail")
                            );
                     );

But this is not:

        "/software/components/sudo/sudo/general_options" =
                list (
                      nlist ("user", "foo",
                             "host", "localhost" ### Error: only one of user and host!
                             "options", nlist ("insults", true)
                            );
                     );

#### The list of `options`

The structure `structure_sudo_default_options` lists the possible
settings and their expected type. See sudoers(5) for a full list and
description.

### THE PRIVILEGE SCALATION SPECIFICATION

Each privilege line in a sudoers has the following format:

        user    host = (run_as_user) OPTIONS: command

And, as such, the type `structure privilege_line` has the following fields:

- `/software/components/sudo/privilege`\_lines/\[n\]/user : mandatory

    The user allowed to run sudo the command. Can be an user, an
    user\_alias, or a group (with a leading %).

- `/software/components/sudo/privilege`\_lines/\[n\]/run\_as : mandatory

    The user to be supplanted. Can be an user, a run\_as\_alias or a group
    (with a leading %).

- `/software/components/sudo/privilege`\_lines/\[n\]/host : mandatory

    The host from where the user can invoke sudo. Can be a host or a host\_alias.

- `/software/components/sudo/privilege`\_lines/\[n\]/options : optional

    If present, it must be either PASSWD or NOPASSWD.

- `/software/components/sudo/privilege`\_lines/\[n\]/cmd : mandatory

    The command to be executed.

Remember that the built-in alias **ALL** is valid for users,
run\_as users, hosts and commands.

### INCLUDING OTHER FILES

The sudoers file allows to include other configuration files, to keep
the configurations simpler. The `includes` field allows to specify a
list of files that should be included.

### EXAMPLES

Try the following settings:

        "/software/components/sudo/general_options" =
                nlist ("options", nlist ("insults", true));
        "/software/components/sudo/user_aliases" =
                nlist ("FOO", list ("127.0.0.1"));
        "/software/components/sudo/privilege_lines" =
                list (nlist ("user", "foo",
                             "run_as", "ALL",
                             "host", "ALL",
                             "cmd", "ALL"));

and see the resulting `/etc/sudoers` .

### SEE ALSO

sudoers(5), visudo(8)

### FILES

`/etc/sudoers`

### WARNINGS

This component cannot perform such as exhaustive analysis as visudo
does. Be careful with what you specify on your profiles or you will
break sudo!!

### TODO

The type type\_host\_sudo needs to be polished
