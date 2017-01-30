object template httpd_conf_el6;

include 'metaconfig/httpd/httpd_conf';

# add apache user and group
include 'apache';

variable HTTPD_OS_FLAVOUR ?= 'el6';

"/software/components/metaconfig/services/{/etc/httpd/conf/httpd.conf}/contents" = create(format('struct/httpd_conf_%s', HTTPD_OS_FLAVOUR));
