# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/spma/apt/schema;

include 'components/spma/schema';

type component_spma_apt = {
    include structure_component
    include component_spma_common
    @{ Allow user defined (i.e. unmanaged) repositories to be present on the system }
    "userrepos" : boolean = false
    @{ Allow user installed (i.e. unmanaged) packages to be present on the system }
    "userpkgs" : boolean = false
};

bind "/software/components/spma" = component_spma_apt;
