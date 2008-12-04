# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/fmonagent/schema;

include quattor/schema;

type component_fmonagent = {
    include structure_component
    "version" ? long
    "no_contact_timeout" : long
};

type "/software/components/fmonagent" = component_fmonagent;
