unique template metaconfig/lvm_conf/config;

include 'metaconfig/lvm_conf/schema';

bind "/software/components/metaconfig/services/{/etc/lvm/lvmlocal.conf}/contents" = lvm_conf_file;

prefix "/software/components/metaconfig/services/{/etc/lvm/lvmlocal.conf}";
"module" = "lvm_conf/main";
