unique template metaconfig/ganesha/config_v2;

variable GANESHA_SERVICE ?= 'nfs-ganesha';
variable GANESHA_MANAGES_GANESHA ?= true;

include 'metaconfig/ganesha/schema_v2';

bind "/software/components/metaconfig/services/{/etc/ganesha/ganesha.conf}/contents" = ganesha_v2_config;

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.conf}";
"daemons" = {if(GANESHA_MANAGES_GANESHA) {dict(GANESHA_SERVICE, "restart")} else {null};};
"module" = "ganesha/2.2/main";

