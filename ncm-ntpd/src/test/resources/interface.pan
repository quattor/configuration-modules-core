object template interface;

include 'only_timeservers_base';

'/system/network/interfaces/eth0' = dict();

prefix "/software/components/ntpd";

'interface' = append(dict('action', 'listen', 'match', 'eth0'));
'interface' = append(dict('action', 'ignore', 'match', '192.168.0.0/16'));
'interface' = append(dict('action', 'drop', 'match', 'ipv6'));
