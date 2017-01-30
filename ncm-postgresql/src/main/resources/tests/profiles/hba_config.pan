object template hba_config;

include 'components/postgresql/schema';

bind "/hba" = postgresql_hba[];

# fake databases for pgsql_hba_database type check
prefix "/software/components/postgresql/databases";
"db1" = dict();
"db2" = dict();
"db3" = dict();
"db4" = dict();

prefix "/hba/0";
"host" = "local";
"database" = list("db1", "db2");
"user" = list("me", "@you");
"method" = "password";

prefix "/hba/1";
"host" = "hostnossl";
"database" = list("db3", "db4");
"user" = list("+me", "everyone");
"address" = "samehost";
"method" = "trust";
"options/opt1" = "value1";
"options/opt2" = "value2";
