object template buoy_mesh;

include 'metaconfig/perfsonar/buoy/mesh';

prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}/contents";

"addrtype" = list("MYSITE", "OS");
"bwctl" = BW_DEFS;
"owamp" = OWAMP_DEFS;
"nodes" = nlist(
    "my.host.domain", nlist(
        "longname", "longname",
        "contact_addr", "1.2.3.5",
        "test_addr", nlist(
            "MYSITE","1.2.3.5",
            "OS","1.2.3.4",
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
    l = nlist(
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

"testspecs/BWTCP_4HR" = nlist(
    "description", "4 Hour TCP Throughput (iperf)",
    "tool", "bwctl/iperf",
    "bw", nlist(
        "interval", 120,
        "start_alpha", 30,
        "duration", 25,
        "report_interval", 2
        ));

"testspecs/LAT_1MIN" = nlist(
    "description", "One-way latency",
    "tool", "powstream",
    "owamp", nlist()
    );

"measurementsets/test_bwtcp4" = nlist(
    "description", "Mesh testing - 4-hour TCP throughput (iperf)",
    "addr_type", "MYSITE",
    "group", "mysite",
    "testspec", "BWTCP_4HR",
);

"measurementsets/test_lat4" = nlist(
    "description", "Mesh testing - 1-minute latency - VSC interface",
    "addr_type", "MYSITE",
    "group", "mysite",
    "testspec", "LAT_1MIN",
);
