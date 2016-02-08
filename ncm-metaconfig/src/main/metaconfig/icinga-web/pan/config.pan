unique template metaconfig/icinga-web/config;

include 'metaconfig/icinga-web/schema';

bind "/software/components/metaconfig/services/{/usr/share/icinga-web/app/config/databases.xml}/contents" = icinga_web_service;

prefix "/software/components/metaconfig/services/{/usr/share/icinga-web/app/config/databases.xml}";
"module" = "icinga-web/databases";
