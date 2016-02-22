unique template metaconfig/keepalived/config;

include 'metaconfig/keepalived/schema';

bind "/software/components/metaconfig/services/{/etc/keepalived/keepalived.conf}/contents" = keepalived_service;

prefix "/software/components/metaconfig/services/{/etc/keepalived/keepalived.conf}";
'daemons' = dict(
    'keepalived', 'reload',
);
'module' = 'keepalived/main';


