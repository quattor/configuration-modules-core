object template php_conf;

include 'metaconfig/httpd/schema';

bind "/software/components/metaconfig/services/{/etc/httpd/conf.d/php.conf}/contents" = httpd_vhosts;

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/php.conf}";
"module" = "httpd/2.4/generic_server";
"daemons/httpd" = "restart";

"/software/components/metaconfig/services/{/etc/httpd/conf.d/php.conf}/contents" = create('struct/php_conf');
