object template config;

include 'metaconfig/pakiti/config';

prefix "/software/components/metaconfig/services/{/etc/pakiti/pakiti2-client.conf}/contents";
"server_name" = 'pakiti.wn.iihe.ac.be';
"port" = 443;
"url" = '/feed/';
"ca_path" = '/etc/grid-security/certificates';
"tag" = 'CLUSTER';
"connection_method" = 'openssl';
