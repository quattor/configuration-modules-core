unique template metaconfig/ncm-ncd/config;

include 'metaconfig/ncm-ncd/schema';

bind "/software/components/metaconfig/services/{/etc/ncm-ncd.conf}/contents" = ncm_ncd;

prefix "/software/components/metaconfig/services/{/etc/ncm-ncd.conf}";
"module" = "ncm-ncd/main";
"mode" = 0644;
