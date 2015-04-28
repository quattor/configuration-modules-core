unique template metaconfig/ganesha/config;

variable GANESHA_FSAL ?= undef;
variable GANESHA_SERVICE ?= format('nfs-ganesha-%s',GANESHA_FSAL);
variable CTDB_MANAGES_GANESHA ?= false;

include 'metaconfig/ganesha/schema';

bind "/software/components/metaconfig/services/{/etc/ganesha/ganesha.nfsd.conf}/contents" = ganesha_config;

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.nfsd.conf}";
"daemons" = {if (CTDB_MANAGES_GANESHA) { null } else { dict(GANESHA_SERVICE, "restart") }};
"module" = "ganesha/main";

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.nfsd.conf}/contents/main";
'SNMP_ADM/snmp_adm_log' = '/var/log/ganesha_snmp_adm.log';

