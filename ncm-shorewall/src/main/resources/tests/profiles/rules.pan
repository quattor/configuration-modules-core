object template rules;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_rules[];

prefix '/config/0';
"action" = "accept";
"dst/zone" = "fw";
"dstport/0" = "8";
"dstport/1" = "9";
"proto" = "icmp";
# default src zone=all
"user" = "myuser";
"group" = "mygroup";

prefix '/config/1';
"action" = "accept";
"dst/zone" = "fw";
"dstport/0" = "22";
"proto" = "tcp";
"src/address/0" = "1.2.3.4/16";
"src/address/1" = "5.6.7.8/32";
"src/interface" = "etx1";
"src/zone" = "ext";
