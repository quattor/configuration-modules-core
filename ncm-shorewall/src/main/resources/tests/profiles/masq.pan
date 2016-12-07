object template masq;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_masq[];

prefix '/config/0';
"dest" = list('out1', 'out2');
"source" = 'eth0';
prefix '/config/1';
"source" = 'eth1';
prefix '/config/2';
"probability" = 0.1;
