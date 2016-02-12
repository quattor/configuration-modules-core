unique template metaconfig/snoopy/config;

include 'metaconfig/snoopy/schema';

bind "/software/components/metaconfig/services/{/etc/snoopy.ini}/contents" = service_snoopy;

prefix "/software/components/metaconfig/services/{/etc/snoopy.ini}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"module" = "snoopy/main";
