object template hosts_kvm;

prefix "/software/components/opennebula";

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
