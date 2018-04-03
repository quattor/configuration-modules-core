object template configure;

include 'simple';

prefix "/software/components/postgresql";
"pg_hba" = "pg_hba plain text";
"config/main/archive_command" = "main archive";
"config/main/port" = 2345;
"initdb/data-checksums" = true;

prefix "/software/components/postgresql/recovery";
"config/standby_mode" = true;
"config/primary_conninfo" = "host=192.168.122.50 application_name=";
"done" = false; # default suffix

prefix "/software/components/postgresql/roles";
"myrole" = "SUPERPOWER";
"otherrole" = "MORE SUPERPOWER";

prefix "/software/components/postgresql/databases";
"db1" = dict(
    "installfile", "/some/file1",
    "lang", "abc1",
    "langfile", "/some/lang1",
    "sql_user", "theuser1",
    "user", "theowner1",
);
"db2" = dict(
    "installfile", "/some/file2",
    "lang", "abc2",
    "langfile", "/some/lang2",
    "sql_user", "theuser2",
    "user", "theowner2",
);
