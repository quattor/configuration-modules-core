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
include 'components/amandaserver/schema';


# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

"/software/components/amandaserver/dependencies/pre" ?=  list ("spma");

"/software/components/amandaserver/active" ?= true;
"/software/components/amandaserver/dispatch" ?= true;
