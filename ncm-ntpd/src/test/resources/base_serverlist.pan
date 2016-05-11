template base_serverlist;

include 'mock_config';

prefix "/software/components/ntpd";

"serverlist" = list();
"serverlist/0" = nlist();
"serverlist/0/server" = "localhost";
