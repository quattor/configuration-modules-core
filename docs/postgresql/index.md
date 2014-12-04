---
layout: documentation
title: postgresql
category: documentation
subcategory: components
menu: 'components.md'
---
Be sure to put a blank line before and after every formatting command

### NAME

postgresql : NCM component to manage PostgreSQL configuration.

### DESCRIPTION

This component allows to manage configuration of PostgreSQL.
It's very basic infucntionality (originally devolped for dcache usage). 

### RESOURCES

- `/software/components/postgresql/config/debug`\_print
Set the debug logging level (default = 15). The default is very verbose (but best to leave as is). 
The component can be a bit aggressive when things don't work, this will log everything. 
- `/software/components/postgresql/pg`\_script\_name
Name of the service to start postgresql (default = postgresql). 
This should allow you to start multiple postgres instances on the same machine.
- `/software/components/postgresql/pg`\_dir
Name of the base diretcory of the postgres install (default = `/var/lib/pgsql`). 
This directory will be used for the installation (eg create the PG\_VERSION in subdirectory data).
- `/software/components/postgresql/pg`\_port
Name of the port used by postgres (default = 5432).
- `/software/components/postgresql/postgresql`\_conf
Full text of the postgresql.conf file
- `/software/components/postgresql/pg`\_hba
Full text of the pg\_hba.conf file
- `/software/components/postgresql/roles`
nlist of roles to create and alter. 
Key is the name of the role (new roles added with CREATE ROLE)
Value is a string used with ALTER ROLE.
- `/software/components/postgresql/databases`
A nlist of databases to create/initialise
Key is the name of the database
- `/software/components/postgresql/databases`/\[db\_name\]/user
OWNER of the database
- `/software/components/postgresql/databases`/\[db\_name\]/installfile
Optional: when a database is freshly created, this file is used to initialise the database (using pgsql -f option) 
- `/software/components/postgresql/databases`/\[db\_name\]/lang
Optional: when a database is freshly created, it set the pg language for the db (useing createlang) (this runs after installfile) 
- `/software/components/postgresql/databases`/\[db\_name\]/langfile
Optional: when a database is freshly created, this file is used to eg add procedures in certain lang (using pgsql -f option) (this runs after succesfull lang) 

- `/software/components/postgresql/databases`/\[db\_name\]/sql\_user
Optional: when a database is freshly created, and the `/software/components/postgresql/databases`/\[db\_name\]/installfile is defined, initialise the database with this user. 
(defaults to the owner of the db as defined in `/software/components/postgresql/databases`/\[db\_name\]/user)

### DEPENDENCIES

None.

### BUGS

None known.



### VERSION

0.1.5

### SEE ALSO

ncm-ncd(1)
