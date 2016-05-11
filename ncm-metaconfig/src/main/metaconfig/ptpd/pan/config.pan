unique template metaconfig/ptpd/config;

include 'metaconfig/ptpd/schema';

bind "/software/components/metaconfig/services/{/etc/ptpd2.conf}/contents" = ptpd_service;

prefix "/software/components/metaconfig/services/{/etc/ptpd2.conf}";
"daemons" = dict(
    "ptpd2", "restart",
);
"module" = "ptpd/main";
