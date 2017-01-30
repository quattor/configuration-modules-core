# ${license-info}
# ${developer-info}
# ${author-info}

################################################################################
# This is 'TPL/config.tpl', a ncm-nagios's file
################################################################################
#
#
################################################################################
unique template components/nagios/config-rpm;
include 'components/nagios/functions';
include 'components/nagios/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

"/software/components/nagios/dependencies/pre" ?=  list ("spma");

"/software/components/nagios/active" ?= true;
"/software/components/nagios/dispatch" ?= true;
