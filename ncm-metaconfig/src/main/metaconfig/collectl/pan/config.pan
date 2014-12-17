unique template metaconfig/collectl/config;

include 'metaconfig/collectl/schema';

bind "/software/components/metaconfig/services/{/etc/collectl.conf}/contents" = collectl_config;

prefix "/software/components/metaconfig/services/{/etc/collectl.conf}";
"daemon" = list("collectl");
"module" = "collectl/main";

prefix "/software/components/metaconfig/services/{/etc/collectl.conf}/contents/main";
"DaemonCommands" = '-f /var/log/collectl -r00:00,7 -m -F60 -s+YZ';
