unique template metaconfig/telegraf/config;

include 'metaconfig/telegraf/schema';

bind "/software/components/metaconfig/services/{/etc/telegraf/telegraf.conf}/contents" = service_telegraf;

prefix "/software/components/metaconfig/services/{/etc/telegraf/telegraf.conf}";

"mode" = 0644;
"owner" = "root";
"group" = "root";
"module" = "telegraf/main";
