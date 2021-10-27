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
