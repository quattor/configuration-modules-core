# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

unique template components/afsclt/config-rpm;
include { 'components/afsclt/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${RELEASE}", "noarch");

 
"/software/components/afsclt/dependencies/pre" ?= list("spma");
"/software/components/afsclt/active" ?= true;
"/software/components/afsclt/dispatch" ?= true;
 
