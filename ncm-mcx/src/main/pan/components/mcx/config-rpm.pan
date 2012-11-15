# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/mcx
#
#
#
#
############################################################

unique template components/mcx/config-rpm;
include { 'components/mcx/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

 
"/software/components/mcx/dependencies/pre" ?= list("directoryservices");
"/software/components/mcx/active" ?= true;
"/software/components/mcx/dispatch" ?= true;
 
