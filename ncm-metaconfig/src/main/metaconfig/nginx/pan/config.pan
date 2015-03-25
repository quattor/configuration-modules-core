unique template metaconfig/nginx/config;

include 'metaconfig/nginx/schema';

bind "/software/components/metaconfig/services/{/etc/nginx/nginx.conf}/contents" = type_nginx;

prefix "/software/components/metaconfig/services/{/etc/nginx/nginx.conf}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"daemon/0" = "nginx";
"module" = "nginx/nginx";

prefix "/software/components/metaconfig/services/{/etc/nginx/nginx.conf}/contents";
"http/0/includes/0" = "/etc/nginx/mime.types";
"global" = nlist();
