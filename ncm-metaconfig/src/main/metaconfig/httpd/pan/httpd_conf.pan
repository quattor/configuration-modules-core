unique template metaconfig/httpd/httpd_conf;

variable METACONFIG_HTTPD_VERSION ?= '2.2';

include 'metaconfig/httpd/schema';

bind "/software/components/metaconfig/services/{/etc/httpd/conf/httpd.conf}/contents" = httpd_global;

prefix "/software/components/metaconfig/services/{/etc/httpd/conf/httpd.conf}";
"module" = format("httpd/%s/httpd_conf", METACONFIG_HTTPD_VERSION);
"daemons/httpd" = "restart";
