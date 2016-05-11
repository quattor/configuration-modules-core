@{ Schemas of all BUOY-MA-related configuration files }

declaration template metaconfig/perfsonar/buoy/schema;

include 'pan/types';

final variable BW_DEFS = nlist(
    "data_dir",
    "/var/lib/perfsonar/perfsonarbuoy_ma/bwctl",
    "central_host", "magikarp.cubone.gent.vsc:8570",
    "timeout", 3600,
    "archive_dir",
    "/var/lib/perfsonar/perfsonarbuoy_ma/bwctl/archive",
    "db", "bwctl",
    );

final variable OWAMP_DEFS = nlist(
    "data_dir",
    "/var/lib/perfsonar/perfsonarbuoy_ma/owamp",
    "central_host", "magikarp.cubone.gent.vsc:8569",
    "timeout", 3600,
    "archive_dir",
    "/var/lib/perfsonar/perfsonarbuoy_ma/owamp/archive",
    "db", "owamp",
    );

type buoy_nodestring = type_fqdn with exists("/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}/contents/nodes/" + SELF) ||
    error ("Node specification must exist: " + SELF);

type buoy_service_globals = {
    "data_dir" : string
    "central_host" : string
    "db" : string
    "timeout" : long(0..)
    "archive_dir" : string
};

type buoy_bw_test = {
    "interval" : long(0..)
    "start_alpha" : long(0..)
    "report_interval" : long(0..)
    "duration" : long(0..) = 60
    "type" : string = "BWTCP"
};

type buoy_owp_test = {
    "interval" : double(0..) = 0.1
    "lossthresh" : double(0..) = 10.0
    "session_count" : long(0..) = 10800
    "sample_count" : long(0..) = 600
    "bucket_width" : double(0..) = 0.0001
};

type buoy_test_spec = {
    "description" : string
    "tool" : string
    "bw" ? buoy_bw_test
    "owamp" ? buoy_owp_test
};


type buoy_measurement_set = {
    "testspec" : string with exists("/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}/contents/testspecs/" + SELF) ||
    error ("Test specification must exist: " + SELF)
    "group" : string with exists("/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}/contents/groups/" + SELF) ||
    error ("Group specification must exist: " + SELF)
    "exclude_self" : boolean = false
    "description" : string
    "addr_type" : string
};

type buoy_node = {
    "longname" : string
    "contact_addr" : type_ip
    "test_addr" : type_ip{}
};

type buoy_nodehash = buoy_node{} with {
    foreach(nodename; n; SELF) {
    	if (!is_fqdn(nodename)) {
    	    error ("Keys for node hash must be FQDNs: " + SELF);
    	};
    };
    true;
};

type buoy_group = {
    "description" : string
    "type" : string with match(SELF, "^(STAR|MESH)")
    "hauptnode" ? buoy_nodestring
    "nodes" : buoy_nodestring[]
    "include_senders" ? type_fqdn[]
    "include_receivers" ? type_fqdn[]
    "senders" ? type_fqdn[]
    "receivers" ? type_fqdn[]
} with SELF["type"] == "STAR" && exists(SELF["hauptnode"]) ||
    SELF["type"] == "MESH" && !exists(SELF["hauptnode"]) ||
    error ("STAR type and hauptnode make sense only when specified together");

type buoy_host = {
    "node" : buoy_nodestring
};

type type_owmesh = {
    "bindir" : string = "/usr/bin"
    "bwctl" : buoy_service_globals
    "owamp" : buoy_service_globals
    "var_dir" : string = "/var/lib"
    "user" : string = "perfsonar"
    "group" : string = "perfsonar"
    "verify_peer_addr" : boolean = false
    "central_data_dir" : string = "/var/lib/perfsonar/perfsonarbuoy_ma"
    "central_db_type" : string = "DBI:mysql"
    "central_db_user" : string = "perfsonar"
    "central_db_pass" : string = "7hc4m1"
    "send_timeout" : long = 60
    "testspecs" : buoy_test_spec{}
    "nodes" : buoy_nodehash
    "localnodes" : buoy_nodestring[]
    "hosts" : buoy_host{}
    "groups" : buoy_group{}
    "measurementsets" : buoy_measurement_set{}
    "addrtype" : string[]
};

