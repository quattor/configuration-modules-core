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
"/software/packages"=pkg_repl("ncm-mcx","1.0.0-1","noarch");
 
"/software/components/mcx/dependencies/pre" ?= list("directoryservices");
"/software/components/mcx/active" ?= true;
"/software/components/mcx/dispatch" ?= true;
 
