object template configure;

include 'simple';

prefix "/software/components/postgresql";
"pg_hba" = "pg_hba plain text";
"config/main/archive_command" = "main archive";
"roles/myrole" = "SUPERPOWER";
"roles/otherrole" = "MORE SUPERPOWER";
"databases/db1" = dict(
    "installfile", "/some/file1",
    "lang", "abc1",
    "langfile", "/some/lang1",
    "sql_user", "theuser1",
    "user", "theowner1",
);
"databases/db2" = dict(
    "installfile", "/some/file2",
    "lang", "abc2",
    "langfile", "/some/lang2",
    "sql_user", "theuser2",
    "user", "theowner2",
);
