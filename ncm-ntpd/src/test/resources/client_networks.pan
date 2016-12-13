object template client_networks;

'/software/components/ntpd' ?= dict();

prefix '/software/components/ntpd';

'serverlist' = list();
'serverlist/0' = dict();
'serverlist/0/server' = '127.0.0.1';
'serverlist/0/options' = dict();
'serverlist/0/options/burst' = true;
'serverlist/0/options/prefer' = true;
'serverlist/1' = dict();
'serverlist/1/server' = '::1';
'serverlist/1/options' = dict();
'serverlist/1/options/burst' = true;

'clientnetworks' = list();
'clientnetworks/0' = dict();
'clientnetworks/0/net' = '10.0.0.0';
'clientnetworks/0/mask' = '255.0.0.0';
'clientnetworks/1' = dict();
'clientnetworks/1/net' = '172.16.0.0';
'clientnetworks/1/mask' = '255.240.0.0';
'clientnetworks/2' = dict();
'clientnetworks/2/net' = '192.168.0.0';
'clientnetworks/2/mask' = '255.255.0.0';
