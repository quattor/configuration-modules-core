# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/spma/ips/schema;

include 'components/spma/schema';

type component_spma_ips_type = {
    "bename"        ? string         # BE name to use with IPS commands
    "rejectidr"     : boolean = true # Reject Solaris IDRs on upgrade?
    "freeze"        : boolean = true # Ignore frozen packages?
    "imagedir"      ? string         # Override temporary image directory
};

type component_spma_ips = {
    include structure_component
    include component_spma_common
    "ips"           ? component_spma_ips_type
};

bind "/software/components/spma" = component_spma_ips;
