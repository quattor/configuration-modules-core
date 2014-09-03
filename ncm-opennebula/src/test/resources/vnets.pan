unique template vnets;

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
