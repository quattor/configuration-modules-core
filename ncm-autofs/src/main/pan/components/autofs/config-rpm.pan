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
"/software/packages"=pkg_repl("ncm-autofs","2.0.1-1","noarch");

'/software/components/autofs/version' = '2.0.1';

"/software/components/autofs/dependencies/pre" ?= list("spma");
"/software/components/autofs/active" ?= true;
"/software/components/autofs/dispatch" ?= true;

