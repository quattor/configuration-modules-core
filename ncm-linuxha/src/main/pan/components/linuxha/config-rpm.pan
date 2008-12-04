# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/linuxha
#
#
#
############################################################
 
unique template components/linuxha/config-rpm;
include components/linuxha/schema;

# Package to install
"/software/packages"=pkg_repl("ncm-linuxha","1.1.2-1","noarch");
 
"/software/components/linuxha/dependencies/pre" ?= list("spma");
"/software/components/linuxha/active" ?= true;
"/software/components/linuxha/dispatch" ?= true;
 
