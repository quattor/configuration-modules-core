unique template apache;


prefix "/software/components/accounts/groups";
"apache/gid" = 48;
"icingacmd/gid" = 49;
"icinga/gid" = 500;
"sindes/gid" = 480;

"/software/components/accounts/users/apache" = dict(
    "uid", 48,
    "groups", list("apache", "icingacmd", "icinga"),
    "comment", "apache",
    "shell", "/sbin/nologin",
    "homeDir", "/var/www",
);
