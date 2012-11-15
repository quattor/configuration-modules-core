# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/icinga/config-rpm;
include {'components/icinga/functions'};
include {'components/icinga/schema'};

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

"/software/components/icinga/dependencies/pre" ?=  list ("spma");

"/software/components/icinga/active" ?= true;
"/software/components/icinga/dispatch" ?= true;
