object template client_networks;

'/software/components/ntpd' ?= nlist();

prefix '/software/components/ntpd';

'serverlist' = list();
'serverlist/0' = nlist();
'serverlist/0/server' = 'localhost4';
'serverlist/0/options' = nlist();
'serverlist/0/options/burst' = true;
'serverlist/0/options/prefer' = true;
'serverlist/1' = nlist();
'serverlist/1/server' = 'localhost6';
'serverlist/1/options' = nlist();
'serverlist/1/options/burst' = true;

'clientnetworks' = list();
'clientnetworks/0' = nlist();
'clientnetworks/0/net' = '10.0.0.0';
'clientnetworks/0/mask' = '255.0.0.0';
'clientnetworks/1' = nlist();
'clientnetworks/1/net' = '172.16.0.0';
'clientnetworks/1/mask' = '255.240.0.0';
'clientnetworks/2' = nlist();
'clientnetworks/2/net' = '192.168.0.0';
'clientnetworks/2/mask' = '255.255.0.0';
