object template policy;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_policy[];

prefix '/config/0';
"dst" = "all";
"policy" = "accept";
"src" = "fw";

prefix '/config/1';
"dst" = "all";
"policy" = "accept";
"src" = "int";
"burst" = "abc";
"limit" = "123";

prefix '/config/2';
"dst" = "all";
"loglevel" = "info";
"policy" = "reject";
"src" = "all";
"connlimit" = "alot";
