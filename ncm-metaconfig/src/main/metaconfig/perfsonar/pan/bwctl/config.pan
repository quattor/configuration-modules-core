unique template metaconfig/perfsonar/bwctl/config;

include 'metaconfig/perfsonar/bwctl/schema';

bind "/software/components/metaconfig/services/{/etc/bwctld/bwctld.conf}/contents" = bwctl_server;

bind "/software/components/metaconfig/services/{/var/lib/bwctl/.bwctlrc}/contents" = bwctl_client;

bind "/software/components/metaconfig/services/{/etc/bwctld/bwctld.limits}/contents" = bwctl_limits;

bind "/software/components/metaconfig/services/{/var/lib/perfsonar/.bwctlrc}/contents" = bwctl_client;


prefix "/software/components/metaconfig/services/{/etc/bwctld/bwctld.conf}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"module" = "general";
"daemon/0" = "bwctld";

prefix "/software/components/metaconfig/services/{/var/lib/bwctl/.bwctlrc}";
"module" = "general";
"owner" = "bwctl";
"group" = "bwctl";


# We need this to ensure the bwctl commands run by the beacon accept
# small time schews.
"/software/components/metaconfig/services/{/var/lib/perfsonar/.bwctlrc}" = {
    l = value("/software/components/metaconfig/services/{/var/lib/bwctl/.bwctlrc}");
    l["owner"] = "perfsonar";
    l["group"] = "perfsonar";
    l["daemon"] = list("perfsonarbuoy_bw_master");
    l;
};

prefix "/software/components/metaconfig/services/{/etc/bwctld/bwctld.limits}";
"module" = "perfsonar/bwctl-limits";
"daemon/0" = "bwctld";

