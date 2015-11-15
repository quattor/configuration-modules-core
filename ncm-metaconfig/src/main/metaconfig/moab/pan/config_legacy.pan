unique template metaconfig/moab/config_legacy;

include 'metaconfig/moab/schema';

bind "/software/components/metaconfig/services/{/opt/moab/etc/moab.cfg}/contents" = moab_service_legacy;

prefix "/software/components/metaconfig/services/{/opt/moab/etc/moab.cfg}";
"daemons" = dict(
    "moab", "restart",
);
"module" = "moab/legacy/moab";
