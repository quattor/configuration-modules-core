# ${license-info}
# ${developer-info}
# ${author-info}

################################################################################
# This is 'TPL/config.tpl', a ncm-gmond's file
################################################################################
#
#
################################################################################
unique template components/gmond/config-rpm;
include 'components/gmond/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

"/software/components/gmond/dependencies/pre" ?=  list ("spma", "accounts");

"/software/components/gmond/active" ?= true;
"/software/components/gmond/dispatch" ?= true;

