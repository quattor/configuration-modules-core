object template server;

include 'base';

prefix "/software/components/freeipa/server/dns";
"subnet1.subdomain/subnet" = "10.11.12.0/24";

"subnet2.subdomain" = dict(
    "subnet", "10.11.13.0/24",
    "autoreverse", false,
    );

"subnet3.subdomain" = dict(
    "subnet", "10.11.14.0/24",
    "reverse", "15.11.10",
    );

prefix "/software/components/freeipa/server/hosts";
"host1.subnet1.subdomain" = dict();
"host2.subnet2.subdomain/ip_address" = "10.11.13.1";
"host3.subnet3.subdomain" = dict(
    "ip_address", "10.11.13.1",
    "macaddress", "aa:bb:cc:dd:ee:ff",
    );

prefix "/software/components/freeipa/server/services";
"HTTP/hosts" = list("serv1", "serv2");
"libvirt/hosts" = list("hyp1", "hyp3");
