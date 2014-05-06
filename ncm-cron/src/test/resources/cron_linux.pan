object template cron_linux;

"/system/archetype/os" = "linux";
"/software/components/cron/securitypath" = "/etc";

include "cron_syslog-common";
