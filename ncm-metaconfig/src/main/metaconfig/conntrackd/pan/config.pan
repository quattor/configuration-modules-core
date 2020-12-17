unique template metaconfig/conntrackd/config;

include 'metaconfig/conntrackd/schema';
bind "/software/components/metaconfig/services/{/etc/conntrackd/conntrackd.conf}/contents" = conntrackd_service;

prefix "/software/components/metaconfig/services/{/etc/conntrackd/conntrackd.conf}";
'daemons' = dict(
    'conntrackd', 'restart',
);
'module' = 'conntrackd/main';
