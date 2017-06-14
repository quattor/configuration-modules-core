template base_serverlist_options;

prefix "/software/components/ntpd";

"serverlist/0/server" = "localhost";
"serverlist/0/options/burst" = true;
"serverlist/0/options/prefer" = true;
"serverlist/1/server" = "127.0.0.1";
"serverlist/1/options/burst" = true;
"serverlist/1/options/prefer" = true;
"serverlist/1/options/minpoll" = 4;
"serverlist/1/options/maxpoll" = 16;
