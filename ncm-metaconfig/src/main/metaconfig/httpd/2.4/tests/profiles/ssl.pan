object template ssl;

include 'metaconfig/httpd/schema';

bind "/software/components/metaconfig/services/{/etc/httpd/conf.d/ssl.conf}/contents" = httpd_vhosts;

prefix "/software/components/metaconfig/services/{/etc/httpd/conf.d/ssl.conf}";
"module" = "httpd/2.4/generic_server";
"daemons/httpd" = "restart";

variable FULL_HOSTNAME = 'myhost.domain';
variable HOSTNAME = 'myhost';
variable DB_IP = dict(HOSTNAME, '1.2.3.4');



"/software/components/metaconfig/services/{/etc/httpd/conf.d/ssl.conf}/contents" = create("struct/ssl_conf_el7");



