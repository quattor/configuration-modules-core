object template ports;

include 'metaconfig/cumulus/ports';

prefix "/software/components/metaconfig/services/{/etc/cumulus/ports.conf}/contents";
"default" = 25;
"ports/3" = dict('speed', 40, 'number', 1);
"ports/8" = dict('speed', 10, 'number', 4);
"ports/11" = dict('speed', 10, 'number', 0);
# force last port (index 15 is port number 16)
"ports/15" = dict();
