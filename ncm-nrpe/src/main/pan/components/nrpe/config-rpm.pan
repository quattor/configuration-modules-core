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
include 'components/nrpe/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

"/software/components/nrpe/dependencies/pre" ?=  list ("spma");

"/software/components/nrpe/active" ?= true;
"/software/components/nrpe/dispatch" ?= true;

