# ${license-info}
# ${developer-info}
# ${author-info}

################################################################################
# This is 'TPL/config.tpl', a ncm-gmetad's file
################################################################################
#
#
################################################################################
unique template components/gmetad/config-rpm;
include 'components/gmetad/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

"/software/components/gmetad/dependencies/pre" ?=  list ("spma", "accounts");

"/software/components/gmetad/active" ?= true;
"/software/components/gmetad/dispatch" ?= true;

