# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/directoryservices
#
#
#
#
############################################################

unique template components/directoryservices/config-rpm;
include 'components/directoryservices/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


"/software/components/directoryservices/dependencies/pre" ?= list("directoryservices");
"/software/components/directoryservices/active" ?= true;
"/software/components/directoryservices/dispatch" ?= true;

