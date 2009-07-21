# ${license-info}
# ${developer-info}
# ${author-info}

################################################################################
# This is 'TPL/config.tpl', a ncm-nrpe's file
################################################################################
#
#
################################################################################
unique template components/nrpe/config-rpm;
include {'components/nrpe/schema'};

# Package to install
"/software/packages"=pkg_repl("ncm-nrpe","1.0.6-1","noarch");
"/software/components/nrpe/dependencies/pre" ?=  list ("spma");

"/software/components/nrpe/active" ?= true;
"/software/components/nrpe/dispatch" ?= true;

