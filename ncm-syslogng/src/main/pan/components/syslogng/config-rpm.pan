# ${license-info}
# ${developer-info}
# ${author-info}

################################################################################
# This is 'TPL/config.tpl', a ncm-syslogng's file
################################################################################
#
#
################################################################################
unique template components/syslogng/config-rpm;
include 'components/syslogng/schema';


# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

"/software/components/syslogng/dependencies/pre" ?=  list ("spma");

"/software/components/syslogng/active" ?= true;
"/software/components/syslogng/dispatch" ?= true;
