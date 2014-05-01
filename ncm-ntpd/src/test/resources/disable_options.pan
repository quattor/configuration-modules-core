object template disable_options;

"/software/components/ntpd" = nlist();

include { 'base_serverlist_options' };

prefix "/software/components/ntpd";

#disable monlist
"disable/monitor" = true;
