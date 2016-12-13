template base_serverlist_options;

prefix "/software/components/ntpd";

"serverlist" = list();
"serverlist/0" = dict();
"serverlist/0/server" = "localhost";
"serverlist/0/options" = dict();
"serverlist/0/options/burst" = true;
"serverlist/0/options/prefer" = true;
"serverlist/1" = dict();
"serverlist/1/server" = "127.0.0.1";
"serverlist/1/options" = dict();
"serverlist/1/options/burst" = true;
"serverlist/1/options/prefer" = true;
"serverlist/1/options/minpoll" = 32;
"serverlist/1/options/maxpoll" = 128;
