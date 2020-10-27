unique template metaconfig/chrony/config;

include 'metaconfig/chrony/schema';

bind "/software/components/metaconfig/services/{/etc/chrony.conf}/contents" = chrony_service;

prefix "/software/components/metaconfig/services/{/etc/chrony.conf}";
'daemons/chronyd' = 'restart';
'module' = 'chrony/main';
