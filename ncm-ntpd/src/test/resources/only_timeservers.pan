object template only_timeservers;

"/software/components/ntpd" = nlist();

include { "base_servers" };

include { "base_serverlist" };
