object template daemon;


# generate config file
variable RSYNC_SECRETS_LOC = "/etc/rsyncd.secrets";
variable RSYNCD_HOSTS_ALLOW = list("1.2.3.4", "1.2.3.5");

include 'metaconfig/rsync/daemon';

prefix "/software/components/metaconfig/services/{/etc/rsyncd.conf}/contents";

"log" = "/var/log/rsyncd";
"facility" = "daemon";
"sections/serv1" = dict(
    "comment", "serv1 comment",
    "lock_file", "/var/lock/serv1",
    "auth_users", list("serv1user"),
    "secrets_file", RSYNC_SECRETS_LOC,
    "path", "/var/spool/serv1/rsync",
    "hosts_allow", RSYNCD_HOSTS_ALLOW,
);
"sections/serv2" = dict(
    "comment", "serv2 other comment",
    "lock_file", "/var/lock/serv2.lock",
    "auth_users", list("userserv2"),
    "secrets_file", RSYNC_SECRETS_LOC,
    "path", "/var/run/serv2",
    "hosts_allow", RSYNCD_HOSTS_ALLOW,
);
