# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/autofs
#
#
#
############################################################

unique template components/autofs/config-rpm;
include { 'components/autofs/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


'/software/components/autofs/version' = '${project.version}';

"/software/components/autofs/dependencies/pre" ?= list("spma");
"/software/components/autofs/active" ?= true;
"/software/components/autofs/dispatch" ?= true;

