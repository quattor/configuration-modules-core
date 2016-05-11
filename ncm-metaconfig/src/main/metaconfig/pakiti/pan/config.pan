unique template metaconfig/pakiti/config;

include 'metaconfig/pakiti/schema';
bind "/software/components/metaconfig/services/{/etc/pakiti/pakiti2-client.conf}/contents" = pakiti_client2;
prefix "/software/components/metaconfig/services/{/etc/pakiti/pakiti2-client.conf}";
"module" = "pakiti/client2";
