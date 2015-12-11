unique template metaconfig/cgroups/cgconfig;

include 'metaconfig/cgroups/schema';

# Can only pass a dict as CCM.contents
bind "/software/components/metaconfig/services/{/etc/cgconfig.conf}/contents" = cgroups_cgconfig_service;

prefix  "/software/components/metaconfig/services/{/etc/cgconfig.conf}";
"mode" = 0644;
"module" = "cgroups/cgconfig";
"daemons" = dict("cgconfig", "restart");
