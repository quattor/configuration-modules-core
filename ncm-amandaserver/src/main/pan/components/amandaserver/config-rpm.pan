# ${license-info}
# ${developer-info}
# ${author-info}

################################################################################
# This is 'TPL/config.tpl', a ncm-amandaserver's file
################################################################################
#
#
################################################################################
unique template components/amandaserver/config-rpm;
include {'components/amandaserver/schema'};


# Package to install
"/software/packages"=pkg_repl("ncm-amandaserver","2.0.0-1","noarch");
"/software/components/amandaserver/dependencies/pre" ?=  list ("spma");

"/software/components/amandaserver/active" ?= true;
"/software/components/amandaserver/dispatch" ?= true;
