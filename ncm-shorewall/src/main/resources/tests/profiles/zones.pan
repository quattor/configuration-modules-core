object template zones;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_zones[];

prefix '/config/0';
"zone" = 'fw';
prefix '/config/1';
"zone" = "ext";
"type" = "ipv4";
prefix '/config/2';
"zone" = "ext2";
"parent" = list('a', 'b');
"options" = list("op1", "op2");
"inoptions" = list("iop1", "iop2");
"outoptions" = list("oop1", "oop2");
