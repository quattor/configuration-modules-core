object template simple_tun;

include 'simple_base_profile';

prefix "/system/network/interfaces/tun0";
"type" = "IPIP";
"bootproto" = "none";
"my_inner_ipaddr" = '5.6.7.8';
"my_inner_prefix" = 20;
"my_outer_ipaddr" = '5.6.8.8';

prefix "/system/network/interfaces/tun1";
"type" = "IPIP";
"bootproto" = "none";
"my_inner_ipaddr" = '5.6.7.9';
"my_inner_prefix" = 21;
"my_outer_ipaddr" = '5.6.8.9';
"peer_outer_ipaddr" = '5.6.9.9';
