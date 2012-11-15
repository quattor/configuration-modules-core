# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/drbd
#
#
############################################################
 
unique template components/drbd/config-rpm;
include { 'components/drbd/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

 
'/software/components/drbd/version' ?= '${project.version}';

"/software/components/drbd/dependencies/pre" ?= list("spma");
"/software/components/drbd/active" ?= true;
"/software/components/drbd/dispatch" ?= true;
 
