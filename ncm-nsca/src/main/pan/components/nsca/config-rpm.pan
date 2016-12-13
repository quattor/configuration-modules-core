# ${license-info}
# ${developer-info}
# ${author-info}

################################################################################
# This is 'TPL/config.tpl', a ncm-nsca's file
################################################################################
#
#
################################################################################
unique template components/nsca/config-rpm;
include 'components/nsca/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

"/software/components/nsca/dependencies/pre" ?=  list ("spma", "accounts");

"/software/components/nsca/active" ?= true;
"/software/components/nsca/dispatch" ?= true;

