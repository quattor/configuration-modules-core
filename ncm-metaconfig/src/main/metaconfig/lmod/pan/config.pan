unique template metaconfig/lmod/config;

include 'metaconfig/lmod/schema';

bind "/software/components/metaconfig/services/{/etc/lmodrc.lua}/contents" = lmod_service;

prefix "/software/components/metaconfig/services/{/etc/lmodrc.lua}";
"module" = "lmod/main";
"mode" = 0644;
