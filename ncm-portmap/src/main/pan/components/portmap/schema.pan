# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/portmap/schema;

include quattor/schema;

type component_portmap_type = {
  include structure_component
  "enabled" : boolean
};

type "/software/components/portmap" = component_portmap_type;
