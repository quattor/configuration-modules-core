# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/spma/ips/schema;

include 'components/spma/schema';

type component_spma_ips_type = {
    "bename" ? string         # BE name to use with IPS commands
    "cachedir" ? string # SPMA cache directory
    "cmdfile" : string = "/var/tmp/spma-commands" # where to save commands for spma-run script
    "flagfile" ? string # touch this file if there is work to do (i.e. spma-run --execute)
    "freeze" : boolean = true # Ignore frozen packages?
    "imagedir" ? string         # Override temporary image directory
    "pkgpaths" : string[] = list("/software/packages") # where to find package definitions
    "rejectidr" : boolean = true # Reject Solaris IDRs on upgrade?
    "uninstpaths" ? string[] # where to find uninstall definitions
};

type component_spma_ips = {
    include structure_component
    include component_spma_common
    "ips" ? component_spma_ips_type
    @{ Run the SPMA after configuring it }
    "run" ? legacy_binary_affirmation_string
    @{ Allow user installed (i.e. unmanaged) packages to be present on the system }
    "userpkgs" ? legacy_binary_affirmation_string
};

bind "/software/components/spma" = component_spma_ips;
