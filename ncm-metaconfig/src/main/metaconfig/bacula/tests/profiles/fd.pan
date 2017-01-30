object template fd;

include 'metaconfig/bacula/fd';

variable BACULA_DIRECTOR_SHORT = 'director-short-fd';
variable FULL_HOSTNAME = 'my.machine';

prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-fd.conf}/contents/main/Director/0";
"Name" = format("%s-dir", BACULA_DIRECTOR_SHORT);
"Password" = '@/etc/bacula/pw';
"Monitor" = true;

prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-fd.conf}/contents/main/Messages/0";
"Name" = "standard";
"messagedestinations" = list(
    dict(
        "destination", "director",
        "address", format("%s-dir", BACULA_DIRECTOR_SHORT),
        "types", list("all", "!skipped", "!restored"),
    ),
);

prefix "/software/components/metaconfig/services/{/etc/bacula/bacula-fd.conf}/contents/main/FileDaemon/0";
"Name" = format("%s-fd", FULL_HOSTNAME);
"Maximum_Network_Buffer_Size" = 256*1024;
