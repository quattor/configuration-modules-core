# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

unique template components/etcservices/config-rpm;
include 'components/etcservices/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


"/software/components/etcservices/dependencies/pre" ?= list("spma");
"/software/components/etcservices/active" ?= true;
"/software/components/etcservices/dispatch" ?= true;

