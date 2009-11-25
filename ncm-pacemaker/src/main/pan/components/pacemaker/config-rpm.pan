# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/pacemaker
#
#
#
############################################################
 
unique template components/pacemaker/config-rpm;
include { 'components/pacemaker/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-pacemaker","0.6.0-4","noarch");
 
"/software/components/pacemaker/dependencies/pre" ?= list("spma");
"/software/components/pacemaker/active" ?= true;
"/software/components/pacemaker/dispatch" ?= true;
 
