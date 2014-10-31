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
        "ceph_secret", "8371ae8a-386d-44d7-a228-c42de4259c6e",
        "ceph_user", "libvirt",
        "datastore_capacity_check", true,
        "ceph_user_key", "AQCGZr1TeFUBMRBBHExosSnNXvlhuKexxcczpw==",
        "pool_name", "one",
        "type", "IMAGE_DS"
    ),
);

"users" = list(
    nlist(
        "user", "lsimngar",
        "password", "my_fancy_pass",
        "ssh_public_key", "ssh-dss AAAAB3NzaC1kc3MAAACBAOTAivURhUrg2Zh3DqgVd2ofRYKmXKjWDM4LITQJ/Tr6RBWhufdxmJos/w0BG9jFbPWbUyPn1mbRFx9/2JJjaspJMACiNsQV5KD2a2H/yWVBxNkWVUwmq36JNh0Tvx+ts9Awus9MtJIxUeFdvT433DePqRXx9EtX9WCJ1vMyhwcFAAAAFQDcuA4clpwjiL9E/2CfmTKHPCAxIQAAAIEAnCQBn1/tCoEzI50oKFyF5Lvum/TPxh6BugbOKu18Okvwf6/zpsiUTWhpxaa40S4FLzHFopTklTHoG3JaYHuksdP4ZZl1mPPFhCTk0uFsqfEVlK9El9sQak9vXPIi7Tw/dyylmRSq+3p5cmurjXSI93bJIRv7X4pcZlIAvHWtNAYAAACBAOCkwou/wYp5polMTqkFLx7dnNHG4Je9UC8Oqxn2Gq3uu088AsXwaVD9t8tTzXP1FSUlG0zfDU3BX18Ds11p57GZtBSECAkqH1Q6vMUiWcoIwj4hq+xNq3PFLmCG/QP+5Od5JvpbBKqX9frc1UvOJJ3OKSjgWMx6FfHr8PxqqACw lsimngar@OptiPlex-790",
        "quattor", 1
    ),
    nlist(
        "user", "stdweird",
        "password", "another_fancy_pass",
        "quattor", 1
    ),
);

"hosts" = list(
    'hyp101', 'hyp102', 'hyp103', 'hyp104'
);

"ssh_multiplex" = true;
"tm_system_ds" = "ssh";
