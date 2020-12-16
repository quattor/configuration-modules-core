object template snat;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_snat[];

prefix '/config/0';
"action" = 'MASQUERADE';
"dest" = list('out1', 'out2');
"source" = 'eth0';
prefix '/config/1';
"action" = 'SNAT(10.10.20.30)';
"source" = '0.0.0.0/0';
"probability" = 0.1;
