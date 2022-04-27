unique template metaconfig/pakiti/server_config3;

include 'metaconfig/pakiti/server_schema3';
bind "/software/components/metaconfig/services/{/etc/pakiti/Config.php}/contents" = pakiti_server3;
prefix "/software/components/metaconfig/services/{/etc/pakiti/Config.php}";
"module" = "pakiti/server3";
"convert/doublequote" = true;

