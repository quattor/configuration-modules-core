object template kvmvm;

include 'metaconfig/libvirtd/kvmvm';

prefix "/software/components/metaconfig/services/{/etc/libvirt/qemu/autostart/vm.xml}/contents";
"name" = "myhost.example.com";
"memory" = 1024;
"cpus" = 2;
"network_interfaces" = list(
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
