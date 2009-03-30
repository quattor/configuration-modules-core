# ${license-info}
# ${developer-info}
# ${author-info}

################################################################################
# This is 'TPL/config.tpl', a ncm-pnp4nagios's file
################################################################################
#
#
################################################################################
unique template components/pnp4nagios/config-rpm;
include {'components/pnp4nagios/schema'};


# Package to install
"/software/packages"=pkg_repl("ncm-pnp4nagios","1.0.0-1","noarch");
"/software/components/pnp4nagios/dependencies/pre" ?=  list ("spma");
"/software/components/pnp4nagios/dependencies/pre" ?=  list ("nagios");

"/software/components/pnp4nagios/active" ?= true;
"/software/components/pnp4nagios/dispatch" ?= true;
