template base_serverlist;

include 'mock_config';

prefix "/software/components/ntpd";

"serverlist" = list();
"serverlist/0" = dict();
"serverlist/0/server" = "localhost";
