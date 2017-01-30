# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/sudo/config-rpm;
include 'components/sudo/schema';
include 'components/sudo/functions';

# Package to install:
# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

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
