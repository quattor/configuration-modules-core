object template providers;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_providers[];

prefix '/config/0';
"name" = "isp1";
"number" = 23;
"mark" = 4;
"interface" = "abc";
"gateway" = "detect";
"options" = list("loose", "track");

prefix '/config/1';
"name" = "isp2";
"number" = 45;
"interface" = "def";
"gateway" = "4.3.2.1";
"options" = list("balance", "track");
