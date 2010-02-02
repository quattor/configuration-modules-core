# ${license-info}
# ${developer-info}
# ${author-info}

# template pro_software_component_useraccess

unique template components/useraccess/config-rpm;
include {'components/useraccess/schema'};

# Package to install:
# Package to install
"/software/packages"=pkg_repl("ncm-useraccess","1.5.8-1","noarch");
 # This component should be run after ncm-accounts, if present.
"/software/components/useraccess/dependencies/pre" = {
	if (exists ("/software/components/accounts")) {
		return (list("accounts"));
	} else {
		return (list("spma"));
	};
};
"/software/components/useraccess/active" ?= true;
"/software/components/useraccess/dispatch" ?= true;

#valid "/software/components/useraccess" = valid_roles ("/software/components/useraccess");
