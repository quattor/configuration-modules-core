Be sure to put a blank line before and after every formatting command

### NAME

mysql : NCM component to manage MySQL servers and databases

### DESCRIPTION

This component allows to manage configuration of MySQL servers and administer the databases.

### Server Options

### Database Options

Database options are under `/software/components/mysql/databases.` This resource is a nlist with one entry per database. Key is the
database name, value is a nlist allowing to specify options described below.

#### initScript : nlist (optional)

This allows to specify a script to be executed at database creation time. This is a nlist that allows to specify either content
of the MySQL script (key 'content') to execute or the path of a script name (key 'file') to execute.

#### server : string (required)

Name of the server hosting the database. This name must match one entries in `/software/components/mysql/servers` (see above).

Default : none.

#### initOnce: boolean (optional)

When true, the initialization script (initScript) is executed only if the database was not already existing.

#### tableOptions: nlist of nlist (optional)

This resource allows to modify table characteristics. All parameters to the ALTER TABLE command are allowed.
The key is the name of the table, the value is a nlist where the key is the parameter name and the value is parameter
value if any, else an empty string.

#### users : nlist (optional)

List of MySQL users to create and MySQL privileges they have on the database. This is a nlist. Key is the escaped userid, in
user@host format without any quotes. If not @host is present, it defaults to current host.

Value is a nlist with the following possible keys :

- password : user MySQL password. Must be a cleartext password.
- rights : list of MySQL privileges to grant to the user.

### serviceName option

Name of the mysql service. Valid values are 'mysql', 'mysqld' and 'mariadb'. Defaults to 'mysqld'.

### DEPENDENCIES

None.

### BUGS

None known.

Michel Jouvin

Michel Jouvin

### VERSION

1.4.0

### SEE ALSO

ncm-ncd(1)
