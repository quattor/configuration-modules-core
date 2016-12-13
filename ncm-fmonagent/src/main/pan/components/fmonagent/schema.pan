# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/fmonagent/schema;

include 'quattor/schema';

type component_fmonagent = {
    include structure_component
    "LEMONversion" ? long
    "no_contact_timeout" : long = 120
};

bind "/software/components/fmonagent" = component_fmonagent;
