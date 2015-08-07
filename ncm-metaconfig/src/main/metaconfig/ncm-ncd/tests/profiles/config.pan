object template config;

include 'metaconfig/ncm-ncd/config';

prefix "/software/components/metaconfig/services/{/etc/ncm-ncd.conf}/contents";
"include" = list("/a", "/b", "/c");
"facility" = "local2";
"check-noquattor" = true;
