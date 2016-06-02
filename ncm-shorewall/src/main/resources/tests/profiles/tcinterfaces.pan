object template tcinterfaces;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_tcinterfaces[];

prefix '/config/0';
"interface" = "em1";
prefix '/config/1';
"interface" = "em2";
"type" = "internal";
"inbw" = "123mb";
"outbw" = "456mb";
