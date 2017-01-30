object template buoy_mesh;

include 'metaconfig/perfsonar/buoy/mesh';

prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}/contents";

"addrtype" = list("MYSITE", "OS");
"bwctl" = BW_DEFS;
"owamp" = OWAMP_DEFS;
"nodes" = dict(
    "my.host.domain", dict(
        "longname", "longname",
        "contact_addr", "1.2.3.5",
        "test_addr", dict(
            "MYSITE", "1.2.3.5",
            "OS", "1.2.3.4",
            ),
    )
);


"localnodes" = list("my.host.domain");

"hosts" = {
    foreach (name; desc; value("/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}/contents/nodes")) {
        SELF[name]["node"] = name;
    };
    SELF;
};

"groups" = {
    l = dict(
        "description", "Group for nodes",
        "type", "MESH"
        );
    l["nodes"] = list();
    foreach (name; desc; value("/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}/contents/nodes")) {
        if (match(name, '\.domain$')) {
            l["nodes"]=append(l["nodes"], name);
        }
    };
    l["senders"] = l["nodes"];
    l["receivers"] = l["nodes"];
    SELF['mysite'] = l;
    SELF;
};

"testspecs/BWTCP_4HR" = dict(
    "description", "4 Hour TCP Throughput (iperf)",
    "tool", "bwctl/iperf",
    "bw", dict(
        "interval", 120,
        "start_alpha", 30,
        "duration", 25,
        "report_interval", 2
        ));

"testspecs/LAT_1MIN" = dict(
    "description", "One-way latency",
    "tool", "powstream",
    "owamp", dict()
    );

"measurementsets/test_bwtcp4" = dict(
    "description", "Mesh testing - 4-hour TCP throughput (iperf)",
    "addr_type", "MYSITE",
    "group", "mysite",
    "testspec", "BWTCP_4HR",
);

"measurementsets/test_lat4" = dict(
    "description", "Mesh testing - 1-minute latency - VSC interface",
    "addr_type", "MYSITE",
    "group", "mysite",
    "testspec", "LAT_1MIN",
);
