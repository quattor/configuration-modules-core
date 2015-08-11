unique template metaconfig/ganesha/config_v1;

variable GANESHA_FSAL ?= undef;
variable GANESHA_SERVICE ?= format('nfs-ganesha-%s',GANESHA_FSAL);
variable GANESHA_MANAGES_GANESHA ?= true;

include 'metaconfig/ganesha/schema';

bind "/software/components/metaconfig/services/{/etc/ganesha/ganesha.nfsd.conf}/contents" = ganesha_config;

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.nfsd.conf}";
"daemons" = {if(GANESHA_MANAGES_GANESHA) {dict(GANESHA_SERVICE, "restart")} else {null};};
"module" = "ganesha/1.5/main";

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.nfsd.conf}/contents/main";
'SNMP_ADM/snmp_adm_log' = '/var/log/ganesha_snmp_adm.log';

