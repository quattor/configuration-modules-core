# ${license-info}
# ${developer-info}
# ${author-info}

# template pro_software_component_sudo

unique template components/sudo/config-rpm;
include {'components/sudo/schema'};
include {'components/sudo/functions'};

# Package to install:
# Package to install
"/software/packages"=pkg_repl("ncm-sudo","1.1.5-1","noarch");
 # This component should be run after ncm-accounts, if present.
"/software/components/sudo/dependencies/pre" = {
	if (exists ("/software/components/accounts")) {
		return (list("accounts"));
	} else {
		return (list("spma"));
	};
};
"/software/components/sudo/active" ?= true;
"/software/components/sudo/dispatch" ?= true;
