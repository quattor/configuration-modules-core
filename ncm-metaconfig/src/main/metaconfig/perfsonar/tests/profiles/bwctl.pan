unique template bwctl;

include 'metaconfig/perfsonar/bwctl/config';

prefix "/software/components/metaconfig/services/{/etc/bwctld/bwctld.conf}/contents";
"nuttcp_port" = 5006;
"iperf_port" = 5001;
"user" = "bwctl";
"group" = "bwctl";
"control_timeout" = 7200;
"allow_unsync" = true;

prefix "/software/components/metaconfig/services/{/var/lib/bwctl/.bwctlrc}/contents";
"iperf_port" = 5001;
"allow_unsync" = true;

# We need this to ensure the bwctl commands run by the beacon accept
# small time schews.
"/software/components/metaconfig/services/{/var/lib/perfsonar/.bwctlrc}" = {
    l = value("/software/components/metaconfig/services/{/var/lib/bwctl/.bwctlrc}");
    l["owner"] = "perfsonar";
    l["group"] = "perfsonar";
    l["daemons"] = dict("perfsonarbuoy_bw_master", "restart");
    l;
};

prefix "/software/components/metaconfig/services/{/etc/bwctld/bwctld.limits}/contents";
"limit/root" = dict(
    "bandwidth", 1000,
    "duration", 60,
    "allow_udp", true,
    "allow_tcp", true,
    "allow_open_mode", true
    );
"limit/jail" = dict(
    "bandwidth", 1,
    "duration", 1,
    "allow_udp", false,
    "allow_tcp", false,
    "allow_open_mode", false,
    "parent", "root"
    );
"limit/firstlimit" = dict(
    "parent", "root",
    "bandwidth", 900
    );
"limit/otherlimit" = dict(
    "parent", "root",
    "bandwidth", 1000
    );
"assign/0/network" = "default";
"assign/0/restrictions" = "jail";
"assign/1/network" = "172.173.0.0/16";
"assign/1/restrictions" = "otherlimit";
"assign/2/network" = "10.12.0.0/16";
"assign/2/restrictions" = "firstlimit";

