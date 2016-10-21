object template kvmvm;

include 'metaconfig/libvirtd/kvmvm';

prefix "/software/components/metaconfig/services/{/etc/libvirt/qemu/vm.xml}/contents";
"name" = "myhost.example.com";
"memory" = 1024;
"cpus" = 2;
"devices/network" = list(
    dict(
        "bridge", "br100",
        "mac", "AA:00:00:01:02:03",
        "type", "openvswitch",
    ),
    dict(
        "bridge", "br100",
        "mac", "AA:00:00:01:02:04",
        "type", "openvswitch",
    ),
);
"devices/ceph_disk" = list(
    dict(
        "uuid", "d0389287-1be4-4140-b4ed-f083032b48b3",
        "dev", "vda",
        "rbd", dict(
            "name", "one/disk1.vda",
            "ceph_hosts", list("ceph01.example.com", "ceph02.example.com"),
        ),
    ),
    dict(
        "uuid", "d0389287-1be4-4140-b4ed-f083032b48b3",
        "dev", "vdb",
        "rbd", dict(
            "name", "one/disk2.vdb",
            "ceph_hosts", list("ceph01.example.com", "ceph02.example.com"),
        ),
    ),
);
"devices/graphics" = dict(
    "type", "spice",
    "listen", "0.0.0.0",
    "port", 5901,
);
