unique template metaconfig/rsyslog/config;

include 'metaconfig/rsyslog/schema';

bind "/software/components/metaconfig/services/{/etc/rsyslog.conf}/contents" = rsyslog_service;

prefix "/software/components/metaconfig/services/{/etc/rsyslog.conf}";
"daemons/rsyslog" = "restart";
"module" = "rsyslog/main";
"mode" = 0644;

bind "/software/components" = dict with {
    if (exists(SELF['syslog'])) {
        error("Cannot mix metaconfig/rsyslog with syslog component");
    };
    true;
};
