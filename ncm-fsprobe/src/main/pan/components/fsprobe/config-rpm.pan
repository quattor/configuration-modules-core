# ${license-info}
# ${developer-info}
# ${author-info}

# template pro_software_component_fsprobe

unique template components/fsprobe/config-rpm;
include {'components/fsprobe/schema'};
include {'components/fsprobe/functions'};

# Package to install:
# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

 # This component should be run after ncm-accounts, if present.
"/software/components/fsprobe/dependencies/pre" = {
	if (exists ("/software/components/accounts")) {
		return (list("accounts"));
	} else {
		return (list("spma"));
	};
};
"/software/components/fsprobe/active" ?= true;
"/software/components/fsprobe/dispatch" ?= true;

valid "/software/components/fsprobe" = valid_roles ("/software/components/fsprobe");
