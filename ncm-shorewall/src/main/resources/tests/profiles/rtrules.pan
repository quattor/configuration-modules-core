object template rtrules;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_rtrules[];

prefix '/config/0';
"provider" = "isp1";
"priority" = 20000;

prefix '/config/1';
"source" = "eth0";
"dest" = "1.2.3.4";
"provider" = "isp2";
"priority" = 10000;
