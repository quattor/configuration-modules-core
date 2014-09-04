# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/spma/ips/schema;

type component_spma_ips_type = {
    "bename"        ? string         # BE name to use with IPS commands
    "rejectidr"     : boolean = true # Reject Solaris IDRs on upgrade?
    "freeze"        : boolean = true # Ignore frozen packages?
    "imagedir"      ? string         # Override temporary image directory
};

type component_spma_ips = {
    "ips"           ? component_spma_ips_type
};
