template one;

prefix "/software/components/opennebula/rpc";
"user" = "oneadmin";
"password" = "verysecret";
"host" = "myhost.domain";
"port" = 1234;

prefix "/software/components/opennebula";
"vnets" = list(
    nlist(
        "name", "altaria.os",
        "type", "FIXED",
        "bridge", "br100",
        "gateway", "10.141.3.250",
        "dns", "10.141.3.250",
        "network_mask", "255.255.0.0"
    ),
    nlist(
        "name", "altaria.vsc",
        "type", "FIXED",
        "bridge", "br101",
        "gateway", "10.141.3.250",
        "dns", "10.141.3.250",
        "network_mask", "255.255.0.0"
    ),
);

"datastores" = list(
    nlist(
        "name", "ceph.altaria",
        "bridge_list", list("hyp004.cubone.os"),
        "ceph_host", list("ceph001.cubone.os","ceph002.cubone.os","ceph003.cubone.os"),
        "ceph_secret", "35b161e7-a3bc-440f-b007-cb98ac042646",
        "ceph_user", "libvirt",
        "datastore_capacity_check", true,
        "pool_name", "one",
        "type", "IMAGE_DS"
    ),
);

"users" = list(
    nlist(
        "user", "lsimngar",
        "password", "my_fancy_pass"
    ),
    nlist(
        "user", "stdweird",
        "password", "another_fancy_pass"
    ),
);

"hosts" = list(
    'hyp101', 'hyp102', 'hyp103', 'hyp104'
);
