object template tcpri;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_tcpri[];

prefix '/config/0';
"band" = 3;
"address" = "1.2.3.4/5";
prefix '/config/1';
"band" = 1;
"proto" = list("icmp");
"port" = list(8);
prefix '/config/2';
"band" = 1;
"proto" = list("udp", "tcp");
"port" = list(53);
