object template interfaces;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_interfaces[];

prefix '/config/0';
"zone" = "int";
"interface" = "em1";
"broadcast" = list("detect", "somethingelse");
"options" = list("arp_filter", "moreoptions");
prefix '/config/1';
"zone" = "int";
"interface" = "em1";
"port" = 123;
