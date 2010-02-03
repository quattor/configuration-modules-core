# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/named
#
#
#
#
############################################################

unique template components/named/config-rpm;

include { 'components/named/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-named","2.0.0-2","noarch");
 
'/software/components/named/version' ?= '2.0.0';

"/software/components/named/dependencies/pre" ?= list("spma");
"/software/components/named/active" ?= true;
"/software/components/named/dispatch" ?= true;
 
