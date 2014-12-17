unique template metaconfig/named/config;

include 'metaconfig/named/schema';

bind "/software/components/metaconfig/services/{/etc/named.conf}/contents" = named_config;

prefix  "/software/components/metaconfig/services/{/etc/named.conf}";
"mode" = 0640;
"owner" = "root";
"group" = "named";
"module" = "named/named";
"daemon/0" = "named";

