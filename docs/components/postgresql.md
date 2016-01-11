Be sure to put a blank line before and after every formatting command.

### NAME

postgresql : NCM component to manage PostgreSQL configuration.

### DESCRIPTION

This component allows to manage configuration of PostgreSQL.
It's very basic in functionality (originally developed for dcache usage).

### RESOURCES

- `/software/components/postgresql/config/debug_print`

    Set the debug logging level (default = 15). The default is very verbose (but best to leave as is).
    The component can be a bit aggressive when things don't work, this will log everything.

- `/software/components/postgresql/pg_script_name`

    Name of the service to start postgresql (default = postgresql).
    This should allow you to start multiple postgres instances on the same machine.

- `/software/components/postgresql/pg_dir`

    Name of the base directory of the postgres install (default = `/var/lib/pgsql`).
    This directory will be used for the installation (eg. create the PG\_VERSION in subdirectory data).

- `/software/components/postgresql/pg_port`

    Name of the port used by postgres (default = 5432).

- `/software/components/postgresql/postgresql_conf`

    Full text of the postgresql.conf file.

- `/software/components/postgresql/pg_hba`

    Full text of the pg\_hba.conf file.

- `/software/components/postgresql/roles`

    nlist of roles to create and alter.
    Key is the name of the role (new roles added with CREATE ROLE).
    Value is a string used with ALTER ROLE.

- `/software/components/postgresql/databases`

    A nlist of databases to create/initialise.
    Key is the name of the database.

- `/software/components/postgresql/databases/[db_name]/user`

    OWNER of the database.

- `/software/components/postgresql/databases/[db_name]/installfile`

    Optional: when a database is newly created, this file is used to initialise the database (using the pgsql -f option).

- `/software/components/postgresql/databases/[db_name]/lang`

    Optional: when a database is newly created, it sets the pg language for the db (using createlang), this runs after `installfile`.

- `/software/components/postgresql/databases/[db_name]/langfile`

    Optional: when a database is newly created, this file is used to add procedures in certain lang (using pgsql -f option), this runs after successful `lang`.

- `/software/components/postgresql/databases/[db_name]/sql_user`

    Optional: when a database is newly created, and the `/software/components/postgresql/databases/[db_name]/installfile` is defined, initialise the database with this user.
    (defaults to the owner of the db as defined in `/software/components/postgresql/databases/[db_name]/user`)

### DEPENDENCIES

None.

### BUGS

None known.
