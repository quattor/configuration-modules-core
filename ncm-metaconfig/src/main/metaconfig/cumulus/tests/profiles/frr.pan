object template frr;

include 'metaconfig/cumulus/frr';

prefix "/software/components/metaconfig/services/{/etc/frr/frr.conf}/contents/vrf";
"vrf1/0" = dict(
    "network", "1.2.3.4",
    "mask", 24,
    "nexthop", "11.12.13.14",
    );
"vrf1/1" = dict(
    "network", "0.0.0.0",
    "mask", 0,
    "nexthop", "null0"
    );
"some/0" = dict(
    "network", "2.3.4.5",
    "mask", 20,
    "nexthop", "12.13.14.15",
    );

prefix "/software/components/metaconfig/services/{/etc/frr/frr.conf}/contents/bgp";
"vrf1/0" = dict(
    "asn", 12345,
    "routerid", "1.2.3.4",
    "external", "4.5.6.7",
    "ipv4", list("10.1.0.0/24", "172.20.0.0/16"),
    );
"vrf1/1" = dict(
    "asn", 12346,
    "routerid", "1.2.3.5",
    "external", "4.5.6.8",
    "ipv4", list("10.2.0.0/24", "172.21.0.0/16"),
    );
"vrf2/0" = dict(
    "asn", 12346,
    "routerid", "1.2.3.6",
    "external", "4.5.6.8",
    "ipv4", list("10.3.0.0/24", "172.22.0.0/16"),
    );
