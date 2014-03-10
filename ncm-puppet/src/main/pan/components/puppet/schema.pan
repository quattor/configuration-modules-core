declaration template components/puppet/schema;

include { 'quattor/schema' };

type puppet_module_type = {
	"version" ? string
};

type puppet_nodefile_type = {
	"contents" ? string                  #The content is not mandatory. If absent the component will assume that the file is already there
};

type component_puppet_type = {
  include structure_component
  "modules" ? puppet_module_type{}          #List of modules to be loaded (not mandatory). For each module write the required version (or "none")
  "nodefiles" : puppet_nodefile_type{}	    #List of puppet files (mandatory to have at least one)
  "configfile" ? string                     #Puppet config file content. Not mandatory: a default config file comes with the puppet rpm	
};

bind "/software/components/puppet" = component_puppet_type;


