object template cron_solaris;

"/system/archetype/os" = "solaris";
"/software/components/cron/securitypath" = "/etc/cron.d";

include "cron_syslog-common";
