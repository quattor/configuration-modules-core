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
"/software/packages"=pkg_repl("ncm-drbd","1.0.7-1","noarch");
 
'/software/components/drbd/version' ?= '${project.version}';

"/software/components/drbd/dependencies/pre" ?= list("spma");
"/software/components/drbd/active" ?= true;
"/software/components/drbd/dispatch" ?= true;
 
