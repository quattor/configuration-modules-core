object template disable_options;

"/software/components/ntpd" = dict();

include 'base_serverlist_options';

prefix "/software/components/ntpd";

#disable modict
"disable/monitor" = true;
