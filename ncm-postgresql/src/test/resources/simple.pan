unique template simple;

function pkg_repl = { null; };
include 'components/postgresql/config';
"/software/components/postgresql/dependencies/pre" = null;

prefix "/software/components/postgresql";
"pg_engine" = "/usr/pgsql-9.2/bin";
"pg_dir" = "/var/lib/pgsql/myversion";
"pg_port" = "2345";
"pg_version" = "1.2.3";
"pg_script_name" = "myownpostgresql";
