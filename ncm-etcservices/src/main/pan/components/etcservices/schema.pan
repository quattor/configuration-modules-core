# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/etcservices/schema;

include quattor/schema;

type component_etcservices_type = {
	include structure_component
	"entries" : string []
};

type "/software/components/etcservices" = component_etcservices_type;

