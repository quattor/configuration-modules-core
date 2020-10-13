object template config;

include 'metaconfig/conntrackd/config';

"/system/network/interfaces/eth0" = dict();

prefix '/software/components/metaconfig/services/{/etc/conntrackd/conntrackd.conf}/contents';

'sync/mode/CommitTimeout' = 1800;
'sync/mode/DisableExternalCache' = false;

'sync/transport/0/type' = 'UDP';
'sync/transport/0/IPv4_address' = '10.10.20.30';
'sync/transport/0/IPv4_Destination_Address' = '10.10.20.31';
'sync/transport/0/Port' = 3781;
'sync/transport/0/Interface' = 'eth0';
'sync/transport/0/Checksum' = true;

'general/Syslog' = 'on';
'general/filter/protocol/action' = 'Accept';
'general/filter/protocol/protocols' = list('TCP', 'UDP', 'ICMP');


'general/filter/address/action' = 'Ignore';
'general/filter/address/IPv4_address' = list('127.0.0.1', '192.168.1.1');
'general/filter/address/IPv6_address' = list('::1');

'general/filter/state/action' = 'Accept';
'general/filter/state/states' = list('ESTABLISHED', 'CLOSED', 'TIME_WAIT', 'CLOSE_WAIT');
