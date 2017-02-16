object template stoppedrules;

include 'components/shorewall/schema';
bind '/config' = component_shorewall_stoppedrules[];

prefix '/config/0';
"action" = 'ACCEPT';
"src" = list("source", "s2");
"dst" = list("destination", "d2");
"proto" = list('p1', 'p2');
"dport" = list(1, 2);
"sport" = list(11, 12);

prefix '/config/1';
"sport" = list(31);

prefix '/config/2';
"dst" = list("abc");
