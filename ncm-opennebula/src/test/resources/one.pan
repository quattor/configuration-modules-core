template one;


include 'components/opennebula/schema';
bind '/software/components/opennebula' = component_opennebula;


prefix "/software/components/opennebula/rpc";
"user" = "oneadmin";
"password" = "verysecret";
"host" = "myhost.domain";
"port" = 1234;

prefix "/software/components/opennebula/untouchables";
"datastores" = list('system');

prefix "/software/components/opennebula/oned";
"db" = dict(
    "backend", "mysql",
    "server", "localhost",
    "port", 0,
    "user", "oneadmin",
    "passwd", "my-fancy-pass",
    "db_name", "opennebula",
);
"log" = dict(
    "system", "syslog",
    "debug_level", 3,
);
"default_device_prefix" = "vd";
"onegate_endpoint" = "http://hyp004.cubone.os:5030";

prefix "/software/components/opennebula/monitord";
"db" = dict(
    "connections", 10,
);
"log" = dict(
    "system", "syslog",
    "debug_level", 5,
);
"network" = dict(
    "address", "192.168.0.2",
);

prefix "/software/components/opennebula/sched";
"log" = dict(
    "system", "file",
    "debug_level", 4,
);
"sched_interval" = 5;
"live_rescheds" = 1;
"cold_migrate_mode" = 1;
"max_vm" = 9000;

prefix "/software/components/opennebula/sunstone";
"host" = "0.0.0.0";
"tmpdir" = "/tmp";

prefix "/software/components/opennebula/oneflow";
"host" = "0.0.0.0";
"lcm_interval" = 60;
"shutdown_action" = "terminate-hard";

prefix "/software/components/opennebula/kvmrc";
"qemu_protocol" = "qemu+tcp";
"force_destroy" = true;

prefix "/software/components/opennebula/vnm_conf";
"arp_cache_poisoning" = false;

prefix "/software/components/opennebula/pci";
"filter" = list('*:*');

prefix "/software/components/opennebula";

"clusters" = dict(
    "red.cluster", dict(
        "reserved_cpu", 10,
        "reserved_mem", 2097152,
        "labels", list("quattor", "quattor/VO"),
        "description", "red.cluster managed by quattor",
    ),
);

"vmgroups" = dict(
    "ha_group", dict(
        "anti_affined", list('workers', 'backups'),
        "affined", list('db', 'apps'),
        "role", list(
            dict(
                "name", "backup",
                "host_anti_affined", list('1', '2', '3'),
                "policy", "ANTI_AFFINED",
            ),
            dict(
                "name", "apps",
                "host_affined", list('4', '5', '6'),
                "policy", "AFFINED",
            ),
        ),
        "labels", list("quattor", "quattor/ha_group"),
        "description", "New HA VM group managed by quattor",
    ),
);

"vnets" = dict(
    "altaria.os", dict(
        "bridge", "br100",
        "gateway", "10.141.3.250",
        "dns", "10.141.3.250",
        "network_mask", "255.255.0.0",
        "labels", list("quattor", "quattor/private"),
    ),
    "altaria.vsc", dict(
        "bridge", "br101",
        "gateway", "10.141.3.250",
        "dns", "10.141.3.250",
        "network_mask", "255.255.0.0",
        "labels", list("quattor", "quattor/public"),
    ),
    "pool.altaria.os", dict(
        "bridge", "br100",
        "bridge_ovs", "ovsbr0",
        "gateway", "10.141.3.250",
        "dns", "10.141.3.250",
        "network_mask", "255.255.0.0",
        "vlan", true,
        "vlan_id", 0,
        "vn_mad", "ovswitch",
        "ar", dict(
            "type", "IP4",
            "ip", "10.141.14.100",
            "size", 29
        ),
        "labels", list("quattor", "quattor/vlans"),
    ),
    "vxlan.vmpool.os", dict(
        "gateway", "10.1.20.250",
        "dns", "10.1.20.1",
        "network_mask", "255.255.255.0",
        "vlan", true,
        "vlan_id", 10,
        "vn_mad", "vxlan",
        "ar", dict(
            "type", "IP4",
            "ip", "10.1.20.100",
            "size", 100,
        ),
        "phydev", "ib0",
        "filter_ip_spoofing", true,
        "filter_mac_spoofing", true,
        "labels", list("quattor", "quattor/vlans"),
        "permissions", dict(
            "owner", "lsimngar",
            "group", "users",
            "mode", 0440,
        ),
        "clusters", list("default", "red.cluster"),
    ),
);

"datastores" = dict(
    "ceph.altaria", dict(
        "bridge_list", list("hyp004.cubone.os"),
        "ceph_host", list("ceph001.cubone.os", "ceph002.cubone.os", "ceph003.cubone.os"),
        "ceph_secret", "8371ae8a-386d-44d7-a228-c42de4259c6e",
        "ceph_user", "libvirt",
        "disk_type", "RBD",
        "datastore_capacity_check", true,
        "ceph_user_key", "AQCGZr1TeFUBMRBBHExosSnNXvlhuKexxcczpw==",
        "pool_name", "one",
        "type", "IMAGE_DS",
        "ds_mad", "ceph",
        "labels", list("quattor", "quattor/ceph"),
    ),
    "nfs", dict(
        "datastore_capacity_check", true,
        "ds_mad", "fs",
        "tm_mad", "shared",
        "type", "IMAGE_DS",
        "labels", list("quattor", "quattor/nfs"),
        "permissions", dict(
            "owner", "lsimngar",
            "group", "users",
            "mode", 0440,
        ),
        "clusters", list("red.cluster"),
    ),
    "system", dict(
        "tm_mad", "shared",
        "ds_mad", "fs",
        "type", "SYSTEM_DS",
        "clusters", list("default", "red.cluster"),
    ),
    "rdm", dict(
        "tm_mad", "dev",
        "ds_mad", "dev",
        "type", "IMAGE_DS",
        "disk_type", "BLOCK",
        "datastore_capacity_check", false,
        "labels", list("quattor", "quattor/rdm"),
    ),
    "cephsys.altaria", dict(
        "tm_mad", "ceph",
        "type", "SYSTEM_DS",
        "bridge_list", list("hyp004.cubone.os"),
        "ceph_host", list("ceph001.cubone.os", "ceph002.cubone.os", "ceph003.cubone.os"),
        "ceph_secret", "8371ae8a-386d-44d7-a228-c42de4259c6e",
        "ceph_user", "libvirt",
        "disk_type", "RBD",
        "pool_name", "one",
        "clusters", list("default", "red.cluster"),
    ),
);

"groups" = dict(
    "gvo01", dict(
        "description", "gvo01 group managed by quattor",
        "labels", list("quattor", "quattor/VO"),
    ),
);

"users" = dict(
    "lsimngar", dict(
        "password", "my_fancy_pass",
        "ssh_public_key", list(
            'ssh-dss AAAAB3NzaC1kc3MAAACBAOTAivURhU user@OptiPlex-790',
            'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ hello@mylaptop'
        ),
        "group", "oneadmin",
        "labels", list("quattor", "quattor/localuser"),
    ),
    "stdweird", dict(
        "password", "another_fancy_pass",
    ),
    "serveradmin", dict(
        "password", "yet_another_fancy_pass",
    ),
    "oneadmin", dict(
        "ssh_public_key", list(
            'ssh-dss AAAAB3NzaC1yc2EAAAADAQABAAABAQDI4gvhOpwKbukZP/Tht/GmKcRCBHGn8JadVlgb9U6O/EP/hR1KLDbKY7KVjVOlUcvfawn44SIGsmKCzehYJV2s/XU1QSaaLrjB7n+vfOyj1C3EgzfZcMOHvL51xPuSgIoKd9oER/63B/pUV/BEZK5LEC06O1LgAjwLy2DrHNN3cQdnTbxQ4vM5ggDb/BC+DyRYlN5NG74VFguVQmoqMPA8FYXBvT/bBvIAZFw7piZIQFd6C803dtG61234 another@laptop'
        ),
    ),
);

"hosts" = dict(
    'hyp101', dict(),
    'hyp102', dict(),
    # Add hyp103 in a different cluster
    # and CPU pinning policy
    'hyp103', dict(
        "cluster", "red.cluster",
        "pin_policy", "PINNED",
    ),
    'hyp104', dict(),
);

"ssh_multiplex" = true;
"cfg_group" = "apache";
